; ITSC204 Computer Architecture Final Project
; File: networking.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Description:
; Networking procedures for the TCP client.
; Handles socket creation, server connection,
; sending the request, receiving the data,
; heap buffer allocation, and request parsing.

global recv_buffer
global requested_bytes
global initialize_default_request
global parse_request_argument
global allocate_recv_buffer
global release_recv_buffer
global create_socket
global connect_to_server
global discard_server_prompt
global send_request
global receive_data

section .data

server_addr:
    dw 2              ; AF_INET
    dw 0x901F         ; port 8080 in network byte order
    dd 0x0100007F     ; 127.0.0.1 in network byte order
    dq 0              ; padding so sockaddr_in is 16 bytes total

section .bss
    request_str         resb 4    ; 3 hex digits + null terminator
    request_len         resq 1
    requested_bytes     resq 1
    recv_buffer         resq 1
    original_brk        resq 1
    allocated_brk       resq 1
    prompt_discard_buf  resb 64
    rand_word           resd 1

section .text

initialize_default_request:
    ; Make a random request size each run.
    ; Valid range is 0x100 to 0x5FF.

    mov rax, 318                    ; getrandom
    lea rdi, [rel rand_word]
    mov rsi, 4
    xor rdx, rdx
    syscall

    cmp rax, 4
    jne .random_fail

    mov eax, [rel rand_word]
    xor edx, edx
    mov ecx, 0x500                  ; 0x5FF - 0x100 + 1 = 0x500
    div ecx                         ; remainder in edx = 0 .. 0x4FF
    add edx, 0x100                  ; now 0x100 .. 0x5FF

    mov [rel requested_bytes], rdx
    mov qword [rel request_len], 3

    mov ebx, edx

    ; first hex digit
    mov eax, ebx
    shr eax, 8
    and al, 0x0F
    cmp al, 9
    jbe .digit1_num
    add al, 'A' - 10
    jmp .digit1_store
.digit1_num:
    add al, '0'
.digit1_store:
    mov [rel request_str], al

    ; second hex digit
    mov eax, ebx
    shr eax, 4
    and al, 0x0F
    cmp al, 9
    jbe .digit2_num
    add al, 'A' - 10
    jmp .digit2_store
.digit2_num:
    add al, '0'
.digit2_store:
    mov [rel request_str + 1], al

    ; third hex digit
    mov eax, ebx
    and al, 0x0F
    cmp al, 9
    jbe .digit3_num
    add al, 'A' - 10
    jmp .digit3_store
.digit3_num:
    add al, '0'
.digit3_store:
    mov [rel request_str + 2], al

    mov byte [rel request_str + 3], 0

    xor rax, rax
    ret

.random_fail:
    mov qword [rel request_len], 0
    mov qword [rel requested_bytes], 0
    mov qword [rel recv_buffer], 0
    mov rax, 1
    ret

parse_request_argument:
    ; Input:
    ;   rdi = pointer to null-terminated hex string
    ;
    ; Return:
    ;   rax = 0 on success
    ;   rax = 1 on invalid input
    ;
    ; Accepts a request size in hexadecimal and stores both:
    ;   1. the ASCII string to send to the server
    ;   2. the numeric byte count for allocation and receive logic
    ;
    ; Valid range: 0x100 to 0x5FF

    test rdi, rdi
    jz .parse_fail

    xor r8, r8                     ; numeric value being built
    xor r9, r9                     ; character count
    lea r10, [rel request_str]     ; destination for cleaned request text

.parse_loop:
    mov al, [rdi + r9]
    test al, al
    jz .parse_done

    cmp r9, 3
    jae .parse_fail                ; allow at most 3 hex digits

    cmp al, '0'
    jb .check_upper
    cmp al, '9'
    jbe .digit

.check_upper:
    cmp al, 'A'
    jb .check_lower
    cmp al, 'F'
    jbe .upper

.check_lower:
    cmp al, 'a'
    jb .parse_fail
    cmp al, 'f'
    ja .parse_fail
    sub al, 32                     ; convert lowercase to uppercase

.upper:
    mov [r10 + r9], al
    sub al, 'A'
    add al, 10
    movzx rcx, al
    shl r8, 4
    add r8, rcx
    inc r9
    jmp .parse_loop

.digit:
    mov [r10 + r9], al
    sub al, '0'
    movzx rcx, al
    shl r8, 4
    add r8, rcx
    inc r9
    jmp .parse_loop

.parse_done:
    cmp r9, 0
    je .parse_fail

    cmp r8, 0x100
    jb .parse_fail
    cmp r8, 0x5FF
    ja .parse_fail

    mov byte [r10 + r9], 0
    mov [rel request_len], r9
    mov [rel requested_bytes], r8

    xor rax, rax
    ret

.parse_fail:
    mov qword [rel request_len], 0
    mov qword [rel requested_bytes], 0
    mov qword [rel recv_buffer], 0
    mov rax, 1
    ret

allocate_recv_buffer:
    ; Return:
    ;   rax = 0 on success
    ;   rax = 1 on failure
    ;
    ; This uses sys_brk to grow the process heap and create
    ; a buffer large enough to hold the requested random bytes.

    mov rcx, [rel requested_bytes]
    test rcx, rcx
    jz .alloc_fail

    ; Ask the kernel for the current end of the heap.
    mov rax, 12
    xor rdi, rdi
    syscall

    ; Save the original break so the heap can be restored later.
    mov [rel original_brk], rax
    mov [rel recv_buffer], rax

    ; Calculate the new break after adding the buffer size.
    add rax, rcx
    mov [rel allocated_brk], rax

    ; Request that the heap be expanded to the new break.
    mov rdi, rax
    mov rax, 12
    syscall

    ; On success, sys_brk returns the break we asked for.
    cmp rax, [rel allocated_brk]
    jne .alloc_fail

    xor rax, rax
    ret

.alloc_fail:
    mov qword [rel recv_buffer], 0
    mov rax, 1
    ret

release_recv_buffer:
    ; Return:
    ;   rax = 0 on success
    ;   rax = 1 on failure
    ;
    ; Restore the heap to where it was before allocation.

    mov rdi, [rel original_brk]
    test rdi, rdi
    jz .release_success

    mov rax, 12
    syscall

    cmp rax, [rel original_brk]
    jne .release_fail

    mov qword [rel recv_buffer], 0
    mov qword [rel original_brk], 0
    mov qword [rel allocated_brk], 0

.release_success:
    xor rax, rax
    ret

.release_fail:
    mov rax, 1
    ret

create_socket:
    mov rax, 41     ; syscall number for socket
    mov rdi, 2      ; AF_INET - make it an IPv4 socket
    mov rsi, 1      ; SOCK_STREAM - TCP socket
    mov rdx, 0      ; default protocol
    syscall
    ret

connect_to_server:
    ; expects socket fd in rdi

    mov rax, 42                  ; syscall number for connect
    lea rsi, [rel server_addr]   ; pointer to server address
    mov rdx, 16                  ; size of sockaddr_in
    syscall
    ret

discard_server_prompt:
    ; expects socket fd in rdi
    ;
    ; The provided server writes two fixed startup messages before it reads
    ; our request:
    ;   1. hello_msg  = 10 bytes
    ;   2. enter_msg  = 85 bytes
    ; Read and ignore all 95 bytes here so receive_data only stores the
    ; actual random-byte payload.

    mov r8, 95                   ; total startup bytes to discard

.discard_loop:
    test r8, r8
    jz .discard_done

    mov rdx, r8
    cmp rdx, 64
    jbe .discard_read_ready
    mov rdx, 64

.discard_read_ready:
    mov rax, 0                   ; syscall number for read
    lea rsi, [rel prompt_discard_buf]
    syscall

    cmp rax, 0
    jle .discard_fail

    sub r8, rax
    jmp .discard_loop

.discard_done:
    xor rax, rax
    ret

.discard_fail:
    mov rax, 1
    ret

send_request:
    ; expects socket fd in rdi

    mov rax, 1                  ; syscall number for write
    lea rsi, [rel request_str]  ; pointer to request string
    mov rdx, [rel request_len]  ; current request length
    syscall
    ret

receive_data:
    ; expects socket fd in rdi
    ; returns total bytes received in rax
    ;
    ; Register layout used consistently in this procedure:
    ;   r8  = base pointer to heap receive buffer
    ;   r9  = total number of bytes requested from the server
    ;   r10 = running count of bytes successfully received
    ;
    ; This avoids mixed counter usage and makes the data flow easier to read
    ; during debugging.

    mov r8, [rel recv_buffer]        ; base pointer to heap buffer
    test r8, r8
    jz .receive_fail

    mov r9, [rel requested_bytes]    ; total bytes expected
    test r9, r9
    jz .receive_fail

    xor r10, r10                     ; total_received = 0

.receive_loop:
    cmp r10, r9
    jae .done                        ; stop once requested amount is reached

    mov rdx, r9
    sub rdx, r10                     ; bytes still needed
    jz .done                         ; extra guard, should already be covered

    mov rax, 0                       ; syscall number for read
    lea rsi, [r8 + r10]              ; write after bytes already received
    syscall

    cmp rax, 0
    jle .done                        ; stop on EOF or read error

    add r10, rax
    cmp r10, r9
    jbe .receive_loop

    ; Defensive clamp: if something ever overshoots, return failure instead
    ; of leaving a bad byte count for later file writes or sorting.
    jmp .receive_fail

.done:
    mov rax, r10
    ret

.receive_fail:
    xor rax, rax
    ret
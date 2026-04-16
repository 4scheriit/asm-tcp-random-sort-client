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
global send_request
global receive_data

section .data
    default_request_str db "2FF", 0 ; default request if no argument is provided

server_addr:
    dw 2              ; AF_INET
    dw 0x901F         ; port 8080 in network byte order
    dd 0x0100007F     ; 127.0.0.1 in network byte order
    dq 0              ; padding so sockaddr_in is 16 bytes total

section .bss
    request_str      resb 4       ; up to 3 hex digits plus null terminator
    request_len      resq 1       ; current request string length
    requested_bytes  resq 1       ; numeric value requested from server
    recv_buffer      resq 1       ; holds pointer to heap buffer
    original_brk     resq 1       ; starting program break before allocation
    allocated_brk    resq 1       ; program break after allocation

section .text

initialize_default_request:
    ; Return:
    ;   rax = 0 on success
    ;
    ; Load the default request value of 2FF so the client still works
    ; even when the user does not pass an argument.

    lea rdi, [rel default_request_str]
    jmp parse_request_argument

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

    xor rcx, rcx                        ; total_received = 0
    mov r8, [rel recv_buffer]           ; heap buffer pointer
    mov r9, [rel requested_bytes]       ; number of bytes we expect

    test r8, r8
    jz .done                            ; stop immediately if buffer not allocated

.receive_loop:
    cmp rcx, r9                         ; stop when all requested bytes are read
    jae .done

    mov rax, 0                          ; syscall number for read
    lea rsi, [r8 + rcx]                 ; write after already received bytes
    mov rdx, r9
    sub rdx, rcx                        ; bytes still needed
    syscall

    ; if read failed or returned 0, stop as error/incomplete
    cmp rax, 0
    jle .done

    add rcx, rax                        ; total_received += bytes just read
    jmp .receive_loop

.done:
    mov rax, rcx                        ; return total bytes received
    ret

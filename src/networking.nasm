; ITSC204 Computer Architecture Final Project
; File: networking.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Date: April 16, 2026
; Handles request setup, heap buffer management, and the TCP client networking flow

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

section .data                               ; initialized networking data
server_addr:
    dw 2                                    ; AF_INET = IPv4
    dw 0x901F                               ; port 8080 already stored in network byte order
    dd 0x0100007F                           ; 127.0.0.1 in network byte order
    dq 0                                    ; padding so sockaddr_in stays 16 bytes long

section .bss                                ; uninitialized storage used across the client run
    request_str         resb 4              ; 3 hex digits plus a null terminator
    request_len         resq 1              ; length of the request string we will send
    requested_bytes     resq 1              ; numeric version of the same request
    recv_buffer         resq 1              ; pointer to the heap buffer holding received bytes
    original_brk        resq 1              ; heap end before allocation
    allocated_brk       resq 1              ; heap end after allocation
    prompt_discard_buf  resb 64             ; small scratch buffer for throwing away server text
    rand_word           resd 1              ; 4 random bytes used to build a default request

section .text                               ; executable code starts here
initialize_default_request:
    ; picks a random request size between 0x100 and 0x5FF, then builds the matching hex string

    mov rax, 318                            ; Linux syscall number for getrandom
    lea rdi, [rel rand_word]                ; fill rand_word with random bytes
    mov rsi, 4                              ; request 4 bytes
    xor rdx, rdx                            ; no special flags
    syscall                                 ; ask the kernel for randomness

    cmp rax, 4                              ; did we actually get all 4 bytes
    jne .random_fail                        ; if not, treat initialization as failed

    mov eax, [rel rand_word]                ; load the random value we just got
    xor edx, edx                            ; clear edx before division
    mov ecx, 0x500                          ; size of the valid range: 0x100 through 0x5FF
    div ecx                                 ; remainder lands in edx = 0 .. 0x4FF
    add edx, 0x100                          ; shift that into the allowed range

    mov [rel requested_bytes], rdx          ; save the numeric byte count for allocation/receive logic
    mov qword [rel request_len], 3          ; the request text is always 3 hex characters long

    mov ebx, edx                            ; keep a working copy for nibble-by-nibble conversion

    ; first hex digit
    mov eax, ebx                            ; start from the full value
    shr eax, 8                              ; move the top nibble into the low 4 bits
    and al, 0x0F                            ; isolate that nibble
    cmp al, 9                               ; is it 0-9
    jbe .digit1_num                         ; if so, convert as a number character
    add al, 'A' - 10                        ; otherwise convert 10-15 into A-F
    jmp .digit1_store
.digit1_num:
    add al, '0'                             ; convert 0-9 into ASCII
.digit1_store:
    mov [rel request_str], al               ; store the first hex character

    ; second hex digit
    mov eax, ebx                            ; start from the same value again
    shr eax, 4                              ; move the middle nibble down
    and al, 0x0F                            ; isolate that nibble
    cmp al, 9                               ; is it 0-9
    jbe .digit2_num
    add al, 'A' - 10                        ; otherwise convert 10-15 into A-F
    jmp .digit2_store
.digit2_num:
    add al, '0'                             ; convert 0-9 into ASCII
.digit2_store:
    mov [rel request_str + 1], al           ; store the second hex character

    ; third hex digit
    mov eax, ebx                            ; same value one last time
    and al, 0x0F                            ; bottom nibble already sits in place
    cmp al, 9                               ; is it 0-9
    jbe .digit3_num
    add al, 'A' - 10                        ; otherwise convert 10-15 into A-F
    jmp .digit3_store
.digit3_num:
    add al, '0'                             ; convert 0-9 into ASCII
.digit3_store:
    mov [rel request_str + 2], al           ; store the third hex character

    mov byte [rel request_str + 3], 0       ; null-terminate the string for safety

    xor rax, rax                            ; return 0 for success
    ret

.random_fail:
    mov qword [rel request_len], 0          ; clear request length on failure
    mov qword [rel requested_bytes], 0      ; clear numeric request too
    mov qword [rel recv_buffer], 0          ; make sure buffer pointer is not left stale
    mov rax, 1                              ; return 1 for failure
    ret

parse_request_argument:
    ; input:
    ;   rdi = pointer to a null-terminated hex string
    ;
    ; return:
    ;   rax = 0 on success
    ;   rax = 1 on invalid input
    ;
    ; accepts a user-provided hex request, cleans it up, and stores both the text version and numeric value
    ; valid range: 0x100 to 0x5FF

    test rdi, rdi                           ; make sure the caller passed a real pointer
    jz .parse_fail                          ; null pointer means invalid input

    xor r8, r8                              ; running numeric value being built from the hex text
    xor r9, r9                              ; character counter
    lea r10, [rel request_str]              ; destination for the cleaned request text

.parse_loop:
    mov al, [rdi + r9]                      ; read the next character from the input string
    test al, al                             ; did we hit the null terminator
    jz .parse_done                          ; if so, the input is finished

    cmp r9, 3                               ; we only allow up to 3 hex digits
    jae .parse_fail                         ; anything longer is invalid for this project

    cmp al, '0'                             ; start by checking for a numeric digit
    jb .check_upper                         ; below '0' means it is not numeric
    cmp al, '9'
    jbe .digit                              ; 0-9 goes through the digit path

.check_upper:
    cmp al, 'A'                             ; is it an uppercase hex letter
    jb .check_lower
    cmp al, 'F'
    jbe .upper                              ; A-F is valid as-is

.check_lower:
    cmp al, 'a'                             ; maybe it is lowercase instead
    jb .parse_fail                          ; anything below 'a' is invalid here
    cmp al, 'f'
    ja .parse_fail                          ; anything above 'f' is invalid too
    sub al, 32                              ; convert lowercase a-f into uppercase A-F

.upper:
    mov [r10 + r9], al                      ; store the cleaned uppercase character
    sub al, 'A'                             ; turn A-F into 0-5
    add al, 10                              ; shift that into 10-15
    movzx rcx, al                           ; widen the nibble before adding it
    shl r8, 4                               ; make room for the next hex digit
    add r8, rcx                             ; fold the new nibble into the running value
    inc r9                                  ; move to the next character
    jmp .parse_loop

.digit:
    mov [r10 + r9], al                      ; keep the numeric digit in the cleaned string
    sub al, '0'                             ; turn ASCII '0'-'9' into 0-9
    movzx rcx, al                           ; widen the nibble before adding it
    shl r8, 4                               ; make room for the next hex digit
    add r8, rcx                             ; fold the new nibble into the running value
    inc r9                                  ; move to the next character
    jmp .parse_loop

.parse_done:
    cmp r9, 0                               ; empty input is not valid
    je .parse_fail

    cmp r8, 0x100                           ; make sure the value is inside the allowed range
    jb .parse_fail
    cmp r8, 0x5FF
    ja .parse_fail

    mov byte [r10 + r9], 0                  ; null-terminate the cleaned request string
    mov [rel request_len], r9               ; save the text length for send_request
    mov [rel requested_bytes], r8           ; save the numeric value for allocation/receive logic

    xor rax, rax                            ; return 0 for success
    ret

.parse_fail:
    mov qword [rel request_len], 0          ; clear stored request length
    mov qword [rel requested_bytes], 0      ; clear stored byte count
    mov qword [rel recv_buffer], 0          ; clear buffer pointer to avoid stale state
    mov rax, 1                              ; return 1 so the caller knows parsing failed
    ret

allocate_recv_buffer:
    ; return:
    ;   rax = 0 on success
    ;   rax = 1 on failure
    ;
    ; grows the heap with sys_brk and uses that new space as the receive buffer

    mov rcx, [rel requested_bytes]          ; load how many bytes we need room for
    test rcx, rcx                           ; zero means there is nothing valid to allocate
    jz .alloc_fail

    mov rax, 12                             ; Linux syscall number for brk
    xor rdi, rdi                            ; brk(0) asks for the current heap end
    syscall                                 ; get the current break address

    mov [rel original_brk], rax             ; remember where the heap originally ended
    mov [rel recv_buffer], rax              ; this old break becomes the start of our new buffer

    add rax, rcx                            ; move forward by the requested byte count
    mov [rel allocated_brk], rax            ; save the new heap end we want

    mov rdi, rax                            ; pass the desired new break address
    mov rax, 12                             ; Linux syscall number for brk again
    syscall                                 ; ask the kernel to grow the heap

    cmp rax, [rel allocated_brk]            ; success means brk returned the exact address we asked for
    jne .alloc_fail                         ; anything else means allocation did not fully work

    xor rax, rax                            ; return 0 for success
    ret

.alloc_fail:
    mov qword [rel recv_buffer], 0          ; clear the buffer pointer on failure
    mov rax, 1                              ; return 1 so the caller can stop early
    ret

release_recv_buffer:
    ; return:
    ;   rax = 0 on success
    ;   rax = 1 on failure
    ;
    ; shrinks the heap back to where it was before allocate_recv_buffer ran

    mov rdi, [rel original_brk]             ; load the original heap end
    test rdi, rdi                           ; if it is zero, nothing was allocated
    jz .release_success                     ; treat that as a harmless no-op

    mov rax, 12                             ; Linux syscall number for brk
    syscall                                 ; ask the kernel to restore the old heap end

    cmp rax, [rel original_brk]             ; make sure the heap really moved back
    jne .release_fail

    mov qword [rel recv_buffer], 0          ; clear the buffer pointer now that it is no longer valid
    mov qword [rel original_brk], 0         ; clear saved heap markers
    mov qword [rel allocated_brk], 0

.release_success:
    xor rax, rax                            ; return 0 for success
    ret

.release_fail:
    mov rax, 1                              ; return 1 so cleanup code can detect the problem
    ret

create_socket:
    mov rax, 41                             ; Linux syscall number for socket
    mov rdi, 2                              ; AF_INET = IPv4 socket
    mov rsi, 1                              ; SOCK_STREAM = TCP
    mov rdx, 0                              ; default protocol for TCP/IP
    syscall                                 ; create the socket and return its file descriptor
    ret

connect_to_server:
    ; expects socket fd in rdi

    mov rax, 42                             ; Linux syscall number for connect
    lea rsi, [rel server_addr]              ; arg 2 = pointer to the sockaddr_in structure
    mov rdx, 16                             ; arg 3 = size of sockaddr_in
    syscall                                 ; connect the socket to 127.0.0.1:8080
    ret

discard_server_prompt:
    ; expects socket fd in rdi
    ;
    ; the provided server sends two fixed startup messages before it reads our request
    ; this routine reads and throws away those 95 bytes so the receive buffer only gets random data

    mov r8, 95                              ; total number of startup bytes to discard

.discard_loop:
    test r8, r8                             ; anything left to throw away
    jz .discard_done                        ; if not, we are finished

    mov rdx, r8                             ; request however many bytes are still left
    cmp rdx, 64                             ; but cap each read to the temp buffer size
    jbe .discard_read_ready
    mov rdx, 64

.discard_read_ready:
    mov rax, 0                              ; Linux syscall number for read
    lea rsi, [rel prompt_discard_buf]       ; read into the throwaway buffer
    syscall                                 ; pull one chunk of startup text off the socket

    cmp rax, 0                              ; 0 or negative means EOF or read failure
    jle .discard_fail

    sub r8, rax                             ; count down however many bytes we just consumed
    jmp .discard_loop

.discard_done:
    xor rax, rax                            ; return 0 for success
    ret

.discard_fail:
    mov rax, 1                              ; return 1 so the caller knows cleanup failed
    ret

send_request:
    ; expects socket fd in rdi

    mov rax, 1                              ; Linux syscall number for write
    lea rsi, [rel request_str]              ; arg 2 = pointer to the request text like 2FF
    mov rdx, [rel request_len]              ; arg 3 = number of bytes to send
    syscall                                 ; send the request string to the server
    ret

receive_data:
    ; expects socket fd in rdi
    ; returns total bytes received in rax
    ;
    ; register layout in this routine:
    ;   r8  = base pointer to the heap receive buffer
    ;   r9  = total bytes we expect from the server
    ;   r10 = running count of bytes already received

    mov r8, [rel recv_buffer]               ; load the heap buffer base address
    test r8, r8                             ; make sure allocation succeeded first
    jz .receive_fail

    mov r9, [rel requested_bytes]           ; load how many bytes we are trying to collect
    test r9, r9                             ; zero means there is no valid request size
    jz .receive_fail

    xor r10, r10                            ; start with total_received = 0

.receive_loop:
    cmp r10, r9                             ; have we already reached the target byte count
    jae .done                               ; if yes, stop reading

    mov rdx, r9                             ; start with the full expected size
    sub rdx, r10                            ; reduce it to only the bytes still missing
    jz .done                                ; extra guard in case the count is already exact

    mov rax, 0                              ; Linux syscall number for read
    lea rsi, [r8 + r10]                     ; write after the bytes already stored in the buffer
    syscall                                 ; read the next chunk from the socket

    cmp rax, 0                              ; 0 or negative means EOF or read failure
    jle .done                               ; stop and return whatever count we reached

    add r10, rax                            ; add this chunk to the running total
    cmp r10, r9                             ; are we still at or below the requested size
    jbe .receive_loop                       ; if yes, keep reading until we hit the target

    jmp .receive_fail                       ; anything larger would mean the count overshot unexpectedly

.done:
    mov rax, r10                            ; return the total number of bytes collected
    ret

.receive_fail:
    xor rax, rax                            ; return 0 so the caller can treat it as failure
    ret

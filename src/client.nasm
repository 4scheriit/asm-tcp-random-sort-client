; ITSC204 Computer Architecture Final Project
; File: networking.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Description:
; Networking procedures for the TCP client.
; Handles socket creation, server connection,
; sending the request, receiving the data,
; and allocating the receive buffer on the heap.

global recv_buffer
global requested_bytes
global allocate_recv_buffer
global release_recv_buffer
global create_socket
global connect_to_server
global send_request
global receive_data

section .data
    request_str db "2FF"         ; request sent to the server
    request_len equ 3             ; number of characters in "2FF"
    requested_bytes dq 0x2FF      ; 767 bytes requested from the server

server_addr:
    dw 2              ; AF_INET
    dw 0x901F         ; port 8080 in network byte order
    dd 0x0100007F     ; 127.0.0.1 in network byte order
    dq 0              ; padding so sockaddr_in is 16 bytes total

section .bss
    recv_buffer      resq 1       ; holds pointer to heap buffer
    original_brk     resq 1       ; starting program break before allocation
    allocated_brk    resq 1       ; program break after allocation

section .text

allocate_recv_buffer:
    ; Return:
    ;   rax = 0 on success
    ;   rax = 1 on failure
    ;
    ; This uses sys_brk to grow the process heap and create
    ; a buffer large enough to hold the requested random bytes.

    ; Ask the kernel for the current end of the heap.
    mov rax, 12
    xor rdi, rdi
    syscall

    ; Save the original break so the heap can be restored later.
    mov [rel original_brk], rax
    mov [rel recv_buffer], rax

    ; Calculate the new break after adding the buffer size.
    mov rcx, [rel requested_bytes]
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
    mov rdx, request_len        ; length of request string
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

; ITSC204 Computer Architecture Final Project
; File: networking.nasm
; This file handles the request setup, heap buffer,
; socket connection, request send, and receive loop.

global recv_buffer
global requested_bytes
global initialize_default_request
global allocate_recv_buffer
global release_recv_buffer
global create_socket
global connect_to_server
global send_request
global receive_data

section .data
request_str db "2FF", 0
request_len dq 3

server_addr:
    dw 2              ; AF_INET
    dw 0x901F         ; port 8080 in network byte order
    dd 0x0100007F     ; 127.0.0.1
    dq 0              ; pad sockaddr_in to 16 bytes

section .bss
requested_bytes  resq 1
recv_buffer      resq 1
original_brk     resq 1

section .text
initialize_default_request:
    ; set the fixed request this final version uses
    mov qword [rel requested_bytes], 0x2FF
    mov qword [rel recv_buffer], 0
    xor rax, rax
    ret

allocate_recv_buffer:
    ; use sys_brk to grow the heap for the receive buffer
    mov rcx, [rel requested_bytes]
    test rcx, rcx
    jz .alloc_fail

    ; get the current heap end
    mov rax, 12
    xor rdi, rdi
    syscall

    mov [rel original_brk], rax
    mov [rel recv_buffer], rax

    ; ask for old break + requested size
    add rax, rcx
    mov rdi, rax
    mov rax, 12
    syscall

    ; sys_brk gives back the break it ended up using
    cmp rax, rdi
    jne .alloc_fail

    xor rax, rax
    ret

.alloc_fail:
    mov qword [rel recv_buffer], 0
    mov rax, 1
    ret

release_recv_buffer:
    ; put the heap back where it started
    mov rdi, [rel original_brk]
    test rdi, rdi
    jz .release_success

    mov rax, 12
    syscall

    cmp rax, [rel original_brk]
    jne .release_fail

    mov qword [rel recv_buffer], 0
    mov qword [rel original_brk], 0

.release_success:
    xor rax, rax
    ret

.release_fail:
    mov rax, 1
    ret

create_socket:
    mov rax, 41     ; socket
    mov rdi, 2      ; AF_INET
    mov rsi, 1      ; SOCK_STREAM
    mov rdx, 0      ; default protocol
    syscall
    ret

connect_to_server:
    ; rdi = socket fd
    mov rax, 42
    lea rsi, [rel server_addr]
    mov rdx, 16
    syscall
    ret

send_request:
    ; rdi = socket fd
    mov rax, 1
    lea rsi, [rel request_str]
    mov rdx, [rel request_len]
    syscall
    ret

receive_data:
    ; rdi = socket fd
    ; returns total bytes received in rax
    mov r8, [rel recv_buffer]
    test r8, r8
    jz .receive_fail

    mov r9, [rel requested_bytes]
    test r9, r9
    jz .receive_fail

    xor r10, r10                ; total received so far

.receive_loop:
    cmp r10, r9
    jae .done

    mov rdx, r9
    sub rdx, r10                ; bytes still needed

    mov rax, 0                  ; read
    lea rsi, [r8 + r10]
    syscall

    cmp rax, 0
    jle .done                   ; stop on EOF or read error

    add r10, rax
    jmp .receive_loop

.done:
    mov rax, r10
    ret

.receive_fail:
    xor rax, rax
    ret

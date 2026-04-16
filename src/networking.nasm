; ITSC204 Computer Architecture Final Project
; File: networking.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Description:
; Networking procedures for the TCP client.
; Handles socket creation, server connection,
; sending the request, and receiving data.

global recv_buffer
global create_socket
global connect_to_server
global send_request
global receive_data

section .data
    request_str db "2FF"    ; define bytes in memory, message is 2FF
    request_len equ 3       ; define a constant called request_len must equal the char len of the message

server_addr:
    dw 2              ; AF_INET
    dw 0x901F         ; port 8080 which is 0x901F
    dd 0x0100007F     ; 127.0.0.1 which is 0x0100007F
    dq 0              ; padding - ipv4 address structure in linux expects 16 bytes total

section .bss
    recv_buffer resb 1535   ; reserve 1535 bytes of memory for incoming data

section .text

create_socket:
    mov rax, 41     ; syscall number for socket
    mov rdi, 2      ; AF_INET - make it an ipv4 socket
    mov rsi, 1      ; SOCK_STREAM - make this socket TCP not UDP
    mov rdx, 0      ; Use default protocol for ipv4 stream socket
    syscall
    ret

connect_to_server:
    ; expects socket fd (file descriptor) in rdi, rdi holds the sockets id number

    mov rax, 42                  ; syscall number for connect
    lea rsi, [rel server_addr]   ; pointer to server address
    mov rdx, 16                  ; size of sockaddr_in
    syscall
    ret

send_request:
    ; expects socket fd in rdi

    mov rax, 1                  ; syscall number for write
    lea rsi, [rel request_str]  ; pointer to our custom message
    mov rdx, request_len        ; char length in the message
    syscall
    ret

receive_data:
    ; expects socket fd in rdi
    ; returns total bytes received in rax

    xor r8, r8                ; total_received = 0

.receive_loop:
    cmp r8, 767                ; stop when we have all 767 bytes
    jae .done

    mov rax, 0                  ; syscall number for read
    lea rsi, [rel recv_buffer + r8] ; write new bytes after what we already received
    mov rdx, 767
    sub rdx, r8                ; bytes still needed
    syscall

    ; if read failed or returned 0, stop as error/incomplete
    cmp rax, 0
    jle .done

    add r8, rax                ; total_received += bytes just read
    jmp .receive_loop

.done:
    mov rax, r8                ; return total bytes received
    ret
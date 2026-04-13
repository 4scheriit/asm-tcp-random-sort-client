; ITSC204 Computer Architecture Final Project
; File: networking.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Description:
; Networking procedures for the TCP client.
; Handles socket creation, server connection,
; sending the request, and receiving data.

global create_socket
global connect_to_server
global send_request
global receive_data

section .data
    ; networking constants here

section .bss
    ; networking variables / buffers here

section .text

create_socket:
    mov rax, 41     ; syscall number for socket
    mov rdi, 2      ; AF_INET - make it an ipv4 socket
    mov rsi, 1      ; SOCK_STREAM - make this socket TCP not UDP
    mov rdx, 0      ; Use default protocol for ipv4 stream socket
    syscall
    ret

connect_to_server:
    ; connect to server
    ret

send_request:
    ; send request to server
    ret

receive_data:
    ; receive data from server
    ret
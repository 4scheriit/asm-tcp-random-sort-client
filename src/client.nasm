; ITSC204 Computer Architecture Final Project
; File: client.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Date: April 16, 2026
; This is the main flow for the TCP client.
; It sets up the request, gets the random bytes,
; writes them to a file, sorts them, then writes the sorted version.

global _start

; networking.nasm
extern recv_buffer
extern requested_bytes
extern initialize_default_request
extern allocate_recv_buffer
extern release_recv_buffer
extern create_socket
extern connect_to_server
extern send_request
extern receive_data

; fileio.nasm
extern create_output_file
extern write_random_section
extern write_sorted_section
extern close_output_file

; sorting.nasm
extern selection_sort

section .text
_start:
    ; start with "not open yet" values so cleanup is easy
    mov r12, -1                 ; socket fd
    mov r14, -1                 ; output file fd

    ; load the one fixed request this project uses
    call initialize_default_request
    cmp rax, 0
    jne .fail

    ; make heap space for the bytes we expect back
    call allocate_recv_buffer
    cmp rax, 0
    jne .fail

    ; open a TCP socket
    call create_socket
    cmp rax, 0
    jl .fail
    mov r12, rax

    ; connect to the local server
    mov rdi, r12
    call connect_to_server
    cmp rax, 0
    jl .fail

    ; send the request string
    mov rdi, r12
    call send_request
    cmp rax, 0
    jl .fail

    ; read the random bytes into the heap buffer
    mov rdi, r12
    call receive_data
    mov r13, rax

    ; only continue if we got the full amount we asked for
    cmp r13, [rel requested_bytes]
    jne .fail

    ; open output.txt
    call create_output_file
    cmp rax, 0
    jl .fail
    mov r14, rax

    ; write the random bytes section
    mov rdi, r14
    mov rsi, [rel recv_buffer]
    mov rdx, r13
    call write_random_section
    cmp rax, 0
    jne .fail

    ; sort the same buffer in place
    mov rdi, [rel recv_buffer]
    mov rsi, r13
    call selection_sort
    cmp rax, 0
    jne .fail

    ; write the sorted bytes section
    mov rdi, r14
    mov rsi, [rel recv_buffer]
    mov rdx, r13
    call write_sorted_section
    cmp rax, 0
    jne .fail

    ; close the output file
    mov rdi, r14
    call close_output_file
    cmp rax, 0
    jne .fail_after_file_close
    mov r14, -1

    ; close the socket
    mov rdi, r12
    mov rax, 3
    syscall
    mov r12, -1

    ; give the heap back
    call release_recv_buffer

    ; exit success
    mov rax, 60
    xor rdi, rdi
    syscall

.fail_after_file_close:
    mov r14, -1

.fail:
    ; try to clean up whatever was opened before failing
    cmp r14, -1
    je .skip_file_close
    mov rdi, r14
    call close_output_file
    mov r14, -1

.skip_file_close:
    cmp r12, -1
    je .skip_socket_close
    mov rdi, r12
    mov rax, 3
    syscall
    mov r12, -1

.skip_socket_close:
    call release_recv_buffer

    mov rax, 60
    mov rdi, 1
    syscall

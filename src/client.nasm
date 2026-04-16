; ITSC204 Computer Architecture Final Project
; File: client.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Description:
; Main client file for the TCP project.
; Controls the main program flow and calls the networking,
; file output, and sorting procedures.

global _start

; networking.nasm
extern recv_buffer
extern initialize_default_request
extern parse_request_argument
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
    ; -------------------------
    ; Request selection setup
    ; -------------------------
    ; Linux places argc and argv on the stack at program start.
    ; If the user passes one argument, use it as the requested
    ; byte count in hex. Otherwise fall back to the default 2FF.

    mov rax, [rsp]              ; argc
    cmp rax, 2
    jl .use_default_request

    mov rdi, [rsp + 16]         ; argv[1]
    call parse_request_argument
    cmp rax, 0
    jne .exit_fail
    jmp .request_ready

.use_default_request:
    call initialize_default_request
    cmp rax, 0
    jne .exit_fail

.request_ready:
    ; -------------------------
    ; Heap buffer setup
    ; -------------------------

    call allocate_recv_buffer
    cmp rax, 0
    jne .exit_fail

    ; Track descriptors so cleanup logic knows what is open.
    mov r12, -1                 ; socket fd, -1 means not opened yet
    mov r14, -1                 ; output file fd, -1 means not opened yet

    ; -------------------------
    ; Networking setup
    ; -------------------------

    call create_socket
    cmp rax, 0
    jl .cleanup_fail
    mov r12, rax                ; save socket file descriptor

    mov rdi, r12
    call connect_to_server
    cmp rax, 0
    jl .cleanup_fail

    mov rdi, r12
    call send_request
    cmp rax, 0
    jl .cleanup_fail

    mov rdi, r12
    call receive_data
    mov r13, rax                ; save number of bytes received

    ; -------------------------
    ; File setup
    ; -------------------------

    call create_output_file
    cmp rax, 0
    jl .cleanup_fail
    mov r14, rax                ; save output file descriptor

    ; -------------------------
    ; Write random data
    ; -------------------------

    mov rdi, r14                ; file descriptor
    mov rsi, [rel recv_buffer]  ; pointer to heap buffer
    mov rdx, r13                ; buffer length
    call write_random_section
    cmp rax, 0
    jne .cleanup_fail

    ; -------------------------
    ; Sort received data
    ; -------------------------

    mov rdi, [rel recv_buffer]
    mov rsi, r13
    call selection_sort
    cmp rax, 0
    jne .cleanup_fail

    ; -------------------------
    ; Write sorted data
    ; -------------------------

    mov rdi, r14
    mov rsi, [rel recv_buffer]
    mov rdx, r13
    call write_sorted_section
    cmp rax, 0
    jne .cleanup_fail

    ; -------------------------
    ; Cleanup on success
    ; -------------------------

    ; Problem fix:
    ; close_output_file returns 0 on success and 1 on failure.
    ; The old _start code ignored that result. Now we check it.
    mov rdi, r14
    call close_output_file
    cmp rax, 0
    jne .cleanup_fail
    mov r14, -1

    ; Close the socket too so the client does not leak a descriptor.
    cmp r12, -1
    je .skip_socket_close_success
    mov rdi, r12
    mov rax, 3                  ; close syscall
    syscall
    cmp rax, 0
    jl .cleanup_fail
    mov r12, -1

.skip_socket_close_success:
    call release_recv_buffer
    cmp rax, 0
    jne .exit_fail

    mov rax, 60                 ; exit syscall
    xor rdi, rdi                ; return code 0
    syscall

.cleanup_fail:
    ; Best-effort cleanup path for any failure.
    ; Close output file if it was opened.
    cmp r14, -1
    je .skip_file_close
    mov rdi, r14
    call close_output_file
    mov r14, -1

.skip_file_close:
    ; Close the socket if it was opened.
    cmp r12, -1
    je .skip_socket_close_fail
    mov rdi, r12
    mov rax, 3
    syscall
    mov r12, -1

.skip_socket_close_fail:
    ; Release heap buffer if it was allocated.
    call release_recv_buffer

.exit_fail:
    mov rax, 60
    mov rdi, 1
    syscall

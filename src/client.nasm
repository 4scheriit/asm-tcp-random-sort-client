; ITSC204 Computer Architecture Final Project
; File: client.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Date: April 16, 2026
; Description:
; Main client file for the TCP project.
; Controls the main program flow and calls the networking,
; file output, and sorting procedures.

global _start

; networking.nasm
extern recv_buffer
extern requested_bytes
extern initialize_default_request
extern allocate_recv_buffer
extern release_recv_buffer
extern create_socket
extern connect_to_server
extern discard_server_prompt
extern send_request
extern receive_data

; fileio.nasm
extern create_output_file
extern write_random_section
extern write_sorted_section
extern close_output_file

; sorting.nasm
extern selection_sort

section .data
request_msg db "request sent: "
request_msg_len equ $ - request_msg

success_msg db "output.txt created", 10
success_msg_len equ $ - success_msg

newline db 10

section .bss
request_hex resb 3

section .text

_start:
    ; Track descriptors so cleanup knows what is safe to close.
    mov r12, -1                 ; socket fd
    mov r14, -1                 ; output file fd

    ; -------------------------
    ; Request initialization
    ; -------------------------
    call initialize_default_request
    cmp rax, 0
    jne .fail

    ; Build and print the current 3-digit request value.
    call build_request_hex

    mov rax, 1
    mov rdi, 1
    lea rsi, [rel request_msg]
    mov rdx, request_msg_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [rel request_hex]
    mov rdx, 3
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [rel newline]
    mov rdx, 1
    syscall

    call allocate_recv_buffer
    cmp rax, 0
    jne .fail

    ; -------------------------
    ; Networking setup
    ; -------------------------
    call create_socket
    cmp rax, 0
    jl .fail
    mov r12, rax

    mov rdi, r12
    call connect_to_server
    cmp rax, 0
    jl .fail

    ; The server sends its welcome text and first prompt right away.
    ; Read and ignore that startup text before asking for bytes.
    mov rdi, r12
    call discard_server_prompt
    cmp rax, 0
    jne .fail

    mov rdi, r12
    call send_request
    cmp rax, 0
    jl .fail

    mov rdi, r12
    call receive_data
    mov r13, rax                ; total bytes actually received

    ; Make sure we got the full requested payload.
    cmp r13, [rel requested_bytes]
    jne .fail

    ; -------------------------
    ; File setup
    ; -------------------------
    call create_output_file
    cmp rax, 0
    jl .fail
    mov r14, rax

    ; -------------------------
    ; Write random data
    ; -------------------------
    mov rdi, r14
    mov rsi, [rel recv_buffer]
    mov rdx, r13
    call write_random_section
    cmp rax, 0
    jne .fail

    ; -------------------------
    ; Sort received data
    ; -------------------------
    mov rdi, [rel recv_buffer]
    mov rsi, r13
    call selection_sort

    ; -------------------------
    ; Write sorted data
    ; -------------------------
    mov rdi, r14
    mov rsi, [rel recv_buffer]
    mov rdx, r13
    call write_sorted_section
    cmp rax, 0
    jne .fail

    ; -------------------------
    ; Cleanup on success
    ; -------------------------
    mov rdi, r14
    call close_output_file
    cmp rax, 0
    jne .fail_after_file_close
    mov r14, -1

    mov rdi, r12
    mov rax, 3                  ; close socket
    syscall
    mov r12, -1

    call release_recv_buffer

    ; Print a clean success message
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel success_msg]
    mov rdx, success_msg_len
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

.fail_after_file_close:
    mov r14, -1

.fail:
    ; Best-effort cleanup.
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


; ------------------------------------------------------------
; build_request_hex
; Turns requested_bytes into a 3-digit uppercase hex string.
; Example: 0x3A7 -> "3A7"
; ------------------------------------------------------------
build_request_hex:
    mov rbx, [rel requested_bytes]

    ; first digit
    mov rax, rbx
    shr rax, 8
    and al, 0x0F
    call nibble_to_ascii
    mov [rel request_hex], al

    ; second digit
    mov rax, rbx
    shr rax, 4
    and al, 0x0F
    call nibble_to_ascii
    mov [rel request_hex + 1], al

    ; third digit
    mov rax, rbx
    and al, 0x0F
    call nibble_to_ascii
    mov [rel request_hex + 2], al

    ret


; ------------------------------------------------------------
; nibble_to_ascii
; Input:  al = value 0..15
; Output: al = ASCII hex character
; ------------------------------------------------------------
nibble_to_ascii:
    cmp al, 9
    jbe .digit
    add al, 'A' - 10
    ret

.digit:
    add al, '0'
    ret 
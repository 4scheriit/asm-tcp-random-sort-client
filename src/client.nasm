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

section .data
    ; shared constants / strings here

section .bss
    ; shared variables / buffers here

section .text
_start:
    ; -------------------------
    ; Networking setup
    ; -------------------------

    call create_socket
    mov r12, rax              ; save socket file descriptor

    mov rdi, r12
    call connect_to_server

    mov rdi, r12
    call send_request

    mov rdi, r12
    call receive_data
    mov r13, rax              ; save number of bytes received

    ; -------------------------
    ; File setup
    ; -------------------------

    call create_output_file
    mov r14, rax              ; save output file descriptor

    ; -------------------------
    ; Write random data
    ; -------------------------

    mov rdi, r14               ; file descriptor
    lea rsi, [rel recv_buffer] ; buffer pointer
    mov rdx, r13               ; buffer length
    call write_random_section

    ; -------------------------
    ; Sort received data
    ; -------------------------

    lea rdi, [rel recv_buffer]
    mov rsi, r13
    call selection_sort

    ; -------------------------
    ; Write sorted data
    ; -------------------------

    mov rdi, r14
    lea rsi, [rel recv_buffer]
    mov rdx, r13
    call write_sorted_section

    ; -------------------------
    ; Cleanup
    ; -------------------------

    mov rdi, r14
    call close_output_file

    mov rax, 60               ; exit syscall
    xor rdi, rdi              ; return code 0
    syscall
; ITSC204 Computer Architecture Final Project
; File: client.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Description:
; Main client file for the TCP project.
; Controls the main program flow and calls the networking,
; file output, and sorting procedures.

global _start

; networking.nasm
extern create_socket
extern connect_to_server
extern send_request
extern receive_data

; fileio.nasm
extern create_output_file
extern write_random_section
extern write_sorted_section

; sorting.nasm
extern selection_sort

section .data
    ; shared constants / strings here

section .bss
    ; shared variables / buffers here

section .text
_start:
    ; create socket
    call create_socket

    ; connect to server
    call connect_to_server

    ; create output file
    call create_output_file

    ; send request to server
    call send_request

    ; receive random data
    call receive_data

    ; write random data to file
    call write_random_section

    ; sort the data
    call selection_sort

    ; write sorted data to file
    call write_sorted_section

    ; cleanup / exit
    mov rax, 60
    xor rdi, rdi
    syscall
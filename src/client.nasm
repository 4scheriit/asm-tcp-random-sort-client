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
    ; Create socket
    call create_socket

    ; Save the socket file descriptor in r12 so we can use it again later
    mov r12, rax        

    ; Put the saved socket file descriptor into rdi because the next function expects it there
    mov rdi, r12
    
    ; Connect to the server          
    call connect_to_server

    ; Create output file
    call create_output_file

    ; Put the socket file descriptor into rdi again so send_request knows which socket to use
    mov rdi, r12
    
    ; Send the request message to the server
    call send_request

    ; Put the socket file descriptor into rdi again so receive_data knows which socket to read from
    mov rdi, r12
    ; Receive random data from the server
    call receive_data

    ; Save the number of bytes received so we can use that value later
    mov r13, rax

    ; Write random data to file
    call write_random_section

    ; Sort the data
    call selection_sort

    ; Write sorted data to file
    call write_sorted_section

    ; Set up the Linux exit syscall
    mov rax, 60
    ; Exit code 0 means success
    xor rdi, rdi
    ; End the program
    syscall
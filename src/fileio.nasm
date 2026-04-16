; ITSC204 Computer Architecture Final Project
; File: fileio.nasm
; This file opens output.txt, writes the random section,
; writes the sorted section, and closes the file.

global create_output_file
global write_random_section
global write_sorted_section
global close_output_file

section .data
output_filename db "output.txt", 0

random_header db "----- BEGINNING OF RANDOM DATA -----", 10
random_header_len equ $ - random_header

sorted_header db "----- BEGINNING OF SORTED DATA -----", 10
sorted_header_len equ $ - sorted_header

newline db 10

section .text
create_output_file:
    ; O_WRONLY | O_CREAT | O_TRUNC, mode 0644
    mov rax, 2
    lea rdi, [rel output_filename]
    mov rsi, 577
    mov rdx, 0644o
    syscall
    ret

close_output_file:
    ; rdi = file descriptor
    mov rax, 3
    syscall

    cmp rax, 0
    jl .close_error

    xor rax, rax
    ret

.close_error:
    mov rax, 1
    ret

write_random_section:
    ; rdi = file descriptor
    ; rsi = buffer pointer
    ; rdx = buffer length

    ; save the real buffer args before writing the header
    push rdi
    push rsi
    push rdx

    mov rax, 1
    lea rsi, [rel random_header]
    mov rdx, random_header_len
    syscall

    cmp rax, random_header_len
    jne .random_error_after_push

    ; get back the original args
    pop rdx
    pop rsi
    pop rdi

    ; write the random bytes
    mov rax, 1
    syscall

    cmp rax, rdx
    jne .random_error

    ; add one newline after the data
    mov rax, 1
    lea rsi, [rel newline]
    mov rdx, 1
    syscall

    cmp rax, 1
    jne .random_error

    xor rax, rax
    ret

.random_error_after_push:
    pop rdx
    pop rsi
    pop rdi

.random_error:
    mov rax, 1
    ret

write_sorted_section:
    ; rdi = file descriptor
    ; rsi = buffer pointer
    ; rdx = buffer length

    ; save the real buffer args before writing the header
    push rdi
    push rsi
    push rdx

    mov rax, 1
    lea rsi, [rel sorted_header]
    mov rdx, sorted_header_len
    syscall

    cmp rax, sorted_header_len
    jne .sorted_error_after_push

    ; get back the original args
    pop rdx
    pop rsi
    pop rdi

    ; write the sorted bytes
    mov rax, 1
    syscall

    cmp rax, rdx
    jne .sorted_error

    ; add one newline after the data
    mov rax, 1
    lea rsi, [rel newline]
    mov rdx, 1
    syscall

    cmp rax, 1
    jne .sorted_error

    xor rax, rax
    ret

.sorted_error_after_push:
    pop rdx
    pop rsi
    pop rdi

.sorted_error:
    mov rax, 1
    ret

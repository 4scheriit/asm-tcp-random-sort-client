; ITSC204 Computer Architecture Final Project
; File: fileio.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Description:
; File input/output procedures for the TCP client.
; Handles creating the output file and writing
; the random data and sorted data sections.

global create_output_file
global write_random_section
global write_sorted_section
global close_output_file

section .data
    ; Output file name
    output_filename db "output.txt", 0

    ; Header written before the random bytes
    random_header db "----- BEGINNING OF RANDOM DATA -----", 10
    random_header_len equ $ - random_header

    ; Header written before the sorted bytes
    sorted_header db "----- BEGINNING OF SORTED DATA -----", 10
    sorted_header_len equ $ - sorted_header

    ; Single newline byte
    newline db 10

section .text

create_output_file:
    ; Open output.txt for writing
    ; 577 = O_WRONLY + O_CREAT + O_TRUNC
    ; 0644 = owner read/write, others read only
    mov rax, 2
    mov rdi, output_filename
    mov rsi, 577
    mov rdx, 0644o
    syscall
    ret

close_output_file:
    ; Input:
    ;   rdi = file descriptor
    ;
    ; Return:
    ;   rax = 0 if success
    ;   rax = 1 if fail

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
    ; Input:
    ;   rdi = file descriptor
    ;   rsi = pointer to random byte buffer
    ;   rdx = length of random byte buffer
    ;
    ; Return:
    ;   rax = 0 if success
    ;   rax = 1 if fail

    ; Save original arguments before writing the header
    push rdi
    push rsi
    push rdx

    ; Write the random data header
    mov rax, 1
    mov rsi, random_header
    mov rdx, random_header_len
    syscall

    ; Fail if header write failed or was incomplete
    cmp rax, 0
    jl .random_error_after_push
    cmp rax, random_header_len
    jne .random_error_after_push

    ; Restore original arguments
    pop rdx
    pop rsi
    pop rdi

    ; Write the random bytes
    mov rax, 1
    syscall

    ; Fail if data write failed or was incomplete
    cmp rax, 0
    jl .random_error
    cmp rax, rdx
    jne .random_error

    ; Write a newline after the section
    mov rax, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Fail if newline write failed or was incomplete
    cmp rax, 0
    jl .random_error
    cmp rax, 1
    jne .random_error

    xor rax, rax
    ret

.random_error_after_push:
    ; Header failed, so stack values still need to be restored
    pop rdx
    pop rsi
    pop rdi

.random_error:
    mov rax, 1
    ret

write_sorted_section:
    ; Input:
    ;   rdi = file descriptor
    ;   rsi = pointer to sorted byte buffer
    ;   rdx = length of sorted byte buffer
    ;
    ; Return:
    ;   rax = 0 if success
    ;   rax = 1 if fail

    ; Save original arguments before writing the header
    push rdi
    push rsi
    push rdx

    ; Write the sorted data header
    mov rax, 1
    mov rsi, sorted_header
    mov rdx, sorted_header_len
    syscall

    ; Fail if header write failed or was incomplete
    cmp rax, 0
    jl .sorted_error_after_push
    cmp rax, sorted_header_len
    jne .sorted_error_after_push

    ; Restore original arguments
    pop rdx
    pop rsi
    pop rdi

    ; Write the sorted bytes
    mov rax, 1
    syscall

    ; Fail if data write failed or was incomplete
    cmp rax, 0
    jl .sorted_error
    cmp rax, rdx
    jne .sorted_error

    ; Write a newline after the section
    mov rax, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Fail if newline write failed or was incomplete
    cmp rax, 0
    jl .sorted_error
    cmp rax, 1
    jne .sorted_error

    xor rax, rax
    ret

.sorted_error_after_push:
    ; Header failed, so stack values still need to be restored
    pop rdx
    pop rsi
    pop rdi

.sorted_error:
    mov rax, 1
    ret
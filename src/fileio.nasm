; ITSC204 Computer Architecture Final Project
; File: fileio.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Date: April 16, 2026
; Handles output.txt creation, section headers, data writes, and file closing

global create_output_file
global write_random_section
global write_sorted_section
global close_output_file

section .data                               ; initialized data used by the file routines
output_filename db "output.txt", 0          ; name of the output file the client creates

random_header db "----- BEGINNING OF RANDOM DATA -----", 10
random_header_len equ $ - random_header     ; byte length of the random-data header

sorted_header db "----- BEGINNING OF SORTED DATA -----", 10
sorted_header_len equ $ - sorted_header     ; byte length of the sorted-data header

newline db 10                               ; single newline written after each section

section .text                               ; executable code starts here
create_output_file:
    ; opens output.txt as write-only, creates it if missing, and clears old contents first
    mov rax, 2                              ; Linux syscall number for open
    lea rdi, [rel output_filename]          ; arg 1 = pointer to the filename string
    mov rsi, 577                            ; arg 2 = O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 0644o                          ; arg 3 = file permissions rw-r--r--
    syscall                                 ; ask Linux to open/create the file
    ret                                     ; return the file descriptor in rax, or a negative error

close_output_file:
    ; closes the output file descriptor passed in rdi
    mov rax, 3                              ; Linux syscall number for close
    syscall                                 ; close the file

    cmp rax, 0                              ; did close return a negative error value
    jl .close_error                         ; if so, report failure

    xor rax, rax                            ; return 0 for success
    ret

.close_error:
    mov rax, 1                              ; return 1 so the caller knows close failed
    ret

write_random_section:
    ; rdi = file descriptor
    ; rsi = buffer pointer
    ; rdx = buffer length

    ; save the real write arguments before borrowing rsi/rdx for the header write
    push rdi                                ; keep the file descriptor
    push rsi                                ; keep the original data pointer
    push rdx                                ; keep the original byte count

    mov rax, 1                              ; Linux syscall number for write
    lea rsi, [rel random_header]            ; point to the random-data header text
    mov rdx, random_header_len              ; number of bytes in that header
    syscall                                 ; write the section header first

    cmp rax, random_header_len              ; did the full header get written
    jne .random_error_after_push            ; if not, treat it as a write failure

    ; restore the original buffer arguments so the actual random bytes can be written next
    pop rdx                                 ; restore data length
    pop rsi                                 ; restore data pointer
    pop rdi                                 ; restore file descriptor

    mov rax, 1                              ; Linux syscall number for write
    syscall                                 ; write the raw random bytes

    cmp rax, rdx                            ; did we write every requested byte
    jne .random_error                       ; if not, report failure

    ; add one newline so the next section starts cleanly on its own line
    mov rax, 1                              ; Linux syscall number for write
    lea rsi, [rel newline]                  ; pointer to a single newline byte
    mov rdx, 1                              ; write exactly one byte
    syscall                                 ; append the newline

    cmp rax, 1                              ; make sure that newline write succeeded
    jne .random_error                       ; fail if even the newline was incomplete

    xor rax, rax                            ; return 0 for success
    ret

.random_error_after_push:
    pop rdx                                 ; clean the saved length off the stack
    pop rsi                                 ; clean the saved pointer off the stack
    pop rdi                                 ; clean the saved file descriptor off the stack

.random_error:
    mov rax, 1                              ; return 1 so the caller knows this section failed
    ret

write_sorted_section:
    ; rdi = file descriptor
    ; rsi = buffer pointer
    ; rdx = buffer length

    ; save the real write arguments before borrowing rsi/rdx for the header write
    push rdi                                ; keep the file descriptor
    push rsi                                ; keep the original data pointer
    push rdx                                ; keep the original byte count

    mov rax, 1                              ; Linux syscall number for write
    lea rsi, [rel sorted_header]            ; point to the sorted-data header text
    mov rdx, sorted_header_len              ; number of bytes in that header
    syscall                                 ; write the section header first

    cmp rax, sorted_header_len              ; did the full header get written
    jne .sorted_error_after_push            ; if not, treat it as a write failure

    ; restore the original buffer arguments so the sorted bytes can be written next
    pop rdx                                 ; restore data length
    pop rsi                                 ; restore data pointer
    pop rdi                                 ; restore file descriptor

    mov rax, 1                              ; Linux syscall number for write
    syscall                                 ; write the sorted bytes

    cmp rax, rdx                            ; did we write every requested byte
    jne .sorted_error                       ; if not, report failure

    ; add one newline so the file ends cleanly after the sorted section
    mov rax, 1                              ; Linux syscall number for write
    lea rsi, [rel newline]                  ; pointer to a single newline byte
    mov rdx, 1                              ; write exactly one byte
    syscall                                 ; append the newline

    cmp rax, 1                              ; make sure that newline write succeeded
    jne .sorted_error                       ; fail if even the newline was incomplete

    xor rax, rax                            ; return 0 for success
    ret

.sorted_error_after_push:
    pop rdx                                 ; clean the saved length off the stack
    pop rsi                                 ; clean the saved pointer off the stack
    pop rdi                                 ; clean the saved file descriptor off the stack

.sorted_error:
    mov rax, 1                              ; return 1 so the caller knows this section failed
    ret

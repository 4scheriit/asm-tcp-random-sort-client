; ITSC204 Computer Architecture Final Project
; File: sorting.nasm
; This is a simple selection sort for the received bytes.
; It sorts the buffer in ascending order in place.

global selection_sort

section .text
selection_sort:
    ; rdi = pointer to byte buffer
    ; rsi = length
    ; returns rax = 0 on success, 1 on bad input

    test rdi, rdi
    jz .bad_input

    test rsi, rsi
    jz .bad_input

    cmp rsi, 1
    je .done

    xor rcx, rcx                ; i = 0

.outer_loop:
    mov rax, rsi
    dec rax
    cmp rcx, rax
    jae .done

    mov r8, rcx                 ; min_index = i
    mov r9, rcx
    inc r9                      ; j = i + 1

.inner_loop:
    cmp r9, rsi
    jae .maybe_swap

    movzx r10, byte [rdi + r9]
    movzx r11, byte [rdi + r8]

    cmp r10b, r11b
    jae .next_j

    mov r8, r9

.next_j:
    inc r9
    jmp .inner_loop

.maybe_swap:
    cmp r8, rcx
    je .next_i

    mov al, [rdi + rcx]
    mov dl, [rdi + r8]
    mov [rdi + rcx], dl
    mov [rdi + r8], al

.next_i:
    inc rcx
    jmp .outer_loop

.done:
    xor rax, rax
    ret

.bad_input:
    mov rax, 1
    ret

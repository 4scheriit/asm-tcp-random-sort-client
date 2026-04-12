; ITSC204 Computer Architecture Final Project
; File: sorting.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Description:
; Selection sort procedure for the TCP client.
; Handles sorting the random data received
; from the server before it is written to the file.

; Inputs:
;   rdi = pointer to byte buffer
;   rsi = length of buffer
;
; Returns:
;   rax = status code
;         0 = success
;         1 = null pointer
;         2 = invalid length
;         3 = verification failed
;
; Notes:
; - Sorts bytes in ascending order.
; - Uses unsigned comparisons because data is random bytes.
; - Includes pre-checks and post-sort verification.

global selection_sort
global verify_sorted

section .text

; ------------------------------------------------------------
; selection_sort
; ------------------------------------------------------------
selection_sort:
    ; preserve callee-saved registers we use
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; -------------------------
    ; Input validation checks
    ; -------------------------

    ; check for null pointer
    test rdi, rdi
    jz .null_pointer

    ; length 0 is not valid for this project flow
    ; if you want len=0 to be treated as harmless, change this
    test rsi, rsi
    jz .invalid_length

    ; length 1 is already sorted, but valid
    cmp rsi, 1
    je .verify_only

    ; save original arguments for verification later
    mov r12, rdi            ; base pointer
    mov r13, rsi            ; length

    xor rcx, rcx            ; i = 0

.outer_loop:
    ; stop when i >= len - 1
    mov rax, r13
    dec rax
    cmp rcx, rax
    jae .sort_done

    ; min_index = i
    mov r8, rcx

    ; j = i + 1
    mov r9, rcx
    inc r9

.inner_loop:
    cmp r9, r13
    jae .maybe_swap

    ; load arr[j] and arr[min_index]
    movzx r10, byte [r12 + r9]
    movzx r11, byte [r12 + r8]

    ; if arr[j] < arr[min_index], update min_index
    cmp r10b, r11b
    jae .next_j

    mov r8, r9

.next_j:
    inc r9
    jmp .inner_loop

.maybe_swap:
    ; if min_index != i, swap arr[i] and arr[min_index]
    cmp r8, rcx
    je .next_i

    mov al, [r12 + rcx]
    mov bl, [r12 + r8]
    mov [r12 + rcx], bl
    mov [r12 + r8], al

.next_i:
    inc rcx
    jmp .outer_loop

.sort_done:
    ; -------------------------
    ; Post-sort verification
    ; -------------------------
    mov rdi, r12
    mov rsi, r13
    call verify_sorted

    cmp rax, 0
    jne .verification_failed

    xor rax, rax
    jmp .done

.verify_only:
    ; length 1 is automatically sorted
    xor rax, rax
    jmp .done

.null_pointer:
    mov rax, 1
    jmp .done

.invalid_length:
    mov rax, 2
    jmp .done

.verification_failed:
    mov rax, 3

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret


; ------------------------------------------------------------
; verify_sorted
; Checks whether the buffer is sorted in ascending order.
;
; Inputs:
;   rdi = pointer to byte buffer
;   rsi = length
;
; Returns:
;   rax = 0 if sorted
;         1 if not sorted
;         2 if null pointer
;         3 if invalid length
; ------------------------------------------------------------
verify_sorted:
    test rdi, rdi
    jz .verify_null

    test rsi, rsi
    jz .verify_bad_len

    cmp rsi, 1
    je .verify_success

    xor rcx, rcx            ; index = 0

.verify_loop:
    ; stop at len - 1 comparisons
    mov rax, rsi
    dec rax
    cmp rcx, rax
    jae .verify_success

    mov al, [rdi + rcx]
    mov dl, [rdi + rcx + 1]

    ; if current > next => not sorted
    cmp al, dl
    jbe .verify_next

    mov rax, 1
    ret

.verify_next:
    inc rcx
    jmp .verify_loop

.verify_success:
    xor rax, rax
    ret

.verify_null:
    mov rax, 2
    ret

.verify_bad_len:
    mov rax, 3
    ret
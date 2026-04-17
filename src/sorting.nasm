; ITSC204 Computer Architecture Final Project
; File: sorting.nasm
; Selection sort for the received bytes, plus a quick verification pass to make sure the buffer really ended up sorted

global selection_sort                       ; main sorting routine called by the client
global verify_sorted                        ; helper used after sorting to double-check the result

section .text                               ; executable code starts here

; selection_sort
; rdi = pointer to the byte buffer
; rsi = number of bytes in that buffer
; returns rax = 0 on success
;               1 on null pointer
;               2 on invalid length
;               3 if the verification pass fails
selection_sort:
    push rbx                                ; save callee-saved registers this routine uses
    push r12
    push r13
    push r14
    push r15

    test rdi, rdi                           ; make sure the caller gave us a real buffer pointer
    jz .null_pointer                        ; a null pointer is not safe to sort

    test rsi, rsi                           ; length must be greater than zero for this project flow
    jz .invalid_length                      ; zero-length input is treated as invalid here

    cmp rsi, 1                              ; one byte is already sorted
    je .verify_only                         ; skip the sort work but still return success

    mov r12, rdi                            ; keep the original buffer pointer for the verification pass
    mov r13, rsi                            ; keep the original length for the verification pass

    xor rcx, rcx                            ; rcx = i, the position we are filling this round

.outer_loop:
    mov rax, r13                            ; start from the full length
    dec rax                                 ; last useful outer-loop index is length - 1
    cmp rcx, rax                            ; are we already at the end of the unsorted range
    jae .sort_done                          ; if yes, the sort is finished

    mov r8, rcx                             ; r8 = min_index, assume the current spot is the smallest

    mov r9, rcx                             ; start j from i
    inc r9                                  ; j = i + 1 so we scan the rest of the buffer to the right

.inner_loop:
    cmp r9, r13                             ; have we checked every remaining byte
    jae .maybe_swap                         ; if yes, either swap or move on

    movzx r10, byte [r12 + r9]              ; load arr[j]
    movzx r11, byte [r12 + r8]              ; load arr[min_index]

    cmp r10b, r11b                          ; is arr[j] smaller than the current minimum
    jae .next_j                             ; if not, keep min_index as it is

    mov r8, r9                              ; found a new smallest value, remember where it is

.next_j:
    inc r9                                  ; move to the next byte in the unsorted section
    jmp .inner_loop                         ; keep looking for the smallest value

.maybe_swap:
    cmp r8, rcx                             ; did the minimum stay at position i
    je .next_i                              ; if yes, no swap is needed this pass

    mov al, [r12 + rcx]                     ; save arr[i]
    mov bl, [r12 + r8]                      ; load the smallest value we found
    mov [r12 + rcx], bl                     ; put that smallest value into position i
    mov [r12 + r8], al                      ; move the old arr[i] value into the old minimum spot

.next_i:
    inc rcx                                 ; advance to the next position to fill
    jmp .outer_loop                         ; repeat the same process for the rest of the buffer

.sort_done:
    mov rdi, r12                            ; pass the original buffer pointer to the checker
    mov rsi, r13                            ; pass the original length too
    call verify_sorted                      ; make sure the finished buffer is really in ascending order

    cmp rax, 0                              ; verify_sorted returns 0 when everything looks correct
    jne .verification_failed                ; any other value means the sort result failed the check

    xor rax, rax                            ; return 0 for success
    jmp .done

.verify_only:
    xor rax, rax                            ; one-byte input is already sorted, so return success
    jmp .done

.null_pointer:
    mov rax, 1                              ; caller passed a null buffer pointer
    jmp .done

.invalid_length:
    mov rax, 2                              ; caller passed an invalid length
    jmp .done

.verification_failed:
    mov rax, 3                              ; sort ran, but the final order check did not pass

.done:
    pop r15                                 ; restore the registers we saved at the start
    pop r14
    pop r13
    pop r12
    pop rbx
    ret


; verify_sorted
; rdi = pointer to the byte buffer
; rsi = number of bytes in that buffer
; returns rax = 0 if sorted
;               1 if the data is out of order
;               2 on null pointer
;               3 on invalid length
verify_sorted:
    test rdi, rdi                           ; make sure the buffer pointer is valid
    jz .verify_null                         ; null pointer means the check cannot continue

    test rsi, rsi                           ; length must be greater than zero here too
    jz .verify_bad_len                      ; zero-length input is treated as invalid

    cmp rsi, 1                              ; a one-byte buffer is automatically sorted
    je .verify_success                      ; no comparisons needed

    xor rcx, rcx                            ; rcx = current index for adjacent comparisons

.verify_loop:
    mov rax, rsi                            ; start from the full length
    dec rax                                 ; last comparison starts at length - 2
    cmp rcx, rax                            ; have we reached the end of the comparison range
    jae .verify_success                     ; if yes, every pair was in order

    mov al, [rdi + rcx]                     ; current byte
    mov dl, [rdi + rcx + 1]                 ; next byte to the right

    cmp al, dl                              ; current must be less than or equal to next
    jbe .verify_next                        ; if that holds, keep checking

    mov rax, 1                              ; found a descending pair, so the buffer is not sorted
    ret

.verify_next:
    inc rcx                                 ; move to the next adjacent pair
    jmp .verify_loop                        ; keep checking until the end

.verify_success:
    xor rax, rax                            ; return 0 when the whole buffer is in order
    ret

.verify_null:
    mov rax, 2                              ; null pointer passed to verify_sorted
    ret

.verify_bad_len:
    mov rax, 3                              ; invalid length passed to verify_sorted
    ret

global _start

extern selection_sort
extern verify_sorted

section .data
    test_data_1 db 9, 4, 7, 1, 3, 8, 2, 6, 5
    len_1 equ $ - test_data_1

    test_data_2 db 1
    len_2 equ $ - test_data_2

    test_data_3 db 5, 5, 5, 5, 5
    len_3 equ $ - test_data_3

    test_data_4 db 10, 200, 3, 255, 0, 100
    len_4 equ $ - test_data_4

section .text
_start:
    ; Test 1
    mov rdi, test_data_1
    mov rsi, len_1
    call selection_sort
    cmp rax, 0
    jne fail_1

    mov rdi, test_data_1
    mov rsi, len_1
    call verify_sorted
    cmp rax, 0
    jne fail_1

    ; Test 2
    mov rdi, test_data_2
    mov rsi, len_2
    call selection_sort
    cmp rax, 0
    jne fail_2

    mov rdi, test_data_2
    mov rsi, len_2
    call verify_sorted
    cmp rax, 0
    jne fail_2

    ; Test 3
    mov rdi, test_data_3
    mov rsi, len_3
    call selection_sort
    cmp rax, 0
    jne fail_3

    mov rdi, test_data_3
    mov rsi, len_3
    call verify_sorted
    cmp rax, 0
    jne fail_3

    ; Test 4
    mov rdi, test_data_4
    mov rsi, len_4
    call selection_sort
    cmp rax, 0
    jne fail_4

    mov rdi, test_data_4
    mov rsi, len_4
    call verify_sorted
    cmp rax, 0
    jne fail_4

    ; success
    mov rax, 60
    xor rdi, rdi
    syscall

fail_1:
    mov rax, 60
    mov rdi, 1
    syscall

fail_2:
    mov rax, 60
    mov rdi, 2
    syscall

fail_3:
    mov rax, 60
    mov rdi, 3
    syscall

fail_4:
    mov rax, 60
    mov rdi, 4
    syscall
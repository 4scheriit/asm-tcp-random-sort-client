; ITSC204 Computer Architecture Final Project
; File: client.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Date: April 16, 2026
; Description:
; Main client file for the TCP project.
; Controls the main program flow and calls the networking,
; file output, and sorting procedures.

global _start                               ; entry point the linker starts from

; symbols imported from networking.nasm
extern recv_buffer                          ; heap buffer pointer where incoming bytes are stored
extern requested_bytes                      ; numeric byte count the client is asking for
extern initialize_default_request           ; sets up the default request value used by the client
extern allocate_recv_buffer                 ; reserves heap space for the received data
extern release_recv_buffer                  ; frees that heap space when the program is done
extern create_socket                        ; creates the TCP socket
extern connect_to_server                    ; connects the socket to the local server
extern discard_server_prompt                ; clears the server's startup text out of the way
extern send_request                         ; sends the 3-digit hex request like 2FF
extern receive_data                         ; reads the random bytes back from the server

; symbols imported from fileio.nasm
extern create_output_file                   ; opens output.txt for writing
extern write_random_section                 ; writes the original unsorted bytes section
extern write_sorted_section                 ; writes the sorted bytes section
extern close_output_file                    ; closes the output file

; symbol imported from sorting.nasm
extern selection_sort                       ; sorts the received bytes in memory

section .data                               ; initialized values used by the program
request_msg db "request sent: "             ; label shown before printing the request value
request_msg_len equ $ - request_msg         ; length of that label

success_msg db "output.txt created", 10     ; message shown when everything finishes cleanly
success_msg_len equ $ - success_msg         ; length of the success message

newline db 10                               ; newline character for cleaner console output

section .bss                                ; uninitialized storage reserved at runtime
request_hex resb 3                          ; room for the request formatted as 3 hex digits

section .text                               ; executable code starts here

_start:
    mov r12, -1                             ; start with "no socket open yet"
    mov r14, -1                             ; start with "no file open yet"

; request setup
    call initialize_default_request         ; load the default request value used by the project
    cmp rax, 0                              ; did setup succeed
    jne .fail                               ; if not, stop and run cleanup

    call build_request_hex                  ; turn the numeric request into printable hex text

    mov rax, 1                              ; Linux syscall: write
    mov rdi, 1                              ; file descriptor 1 = stdout
    lea rsi, [rel request_msg]              ; print the "request sent: " label first
    mov rdx, request_msg_len                ; number of bytes to print
    syscall                                 ; show the label on screen

    mov rax, 1                              ; Linux syscall: write
    mov rdi, 1                              ; stdout again
    lea rsi, [rel request_hex]              ; pointer to the 3-digit request text
    mov rdx, 3                              ; always print exactly 3 characters
    syscall                                 ; show the request value

    mov rax, 1                              ; Linux syscall: write
    mov rdi, 1                              ; stdout again
    lea rsi, [rel newline]                  ; print a newline so later output starts cleanly
    mov rdx, 1                              ; one byte
    syscall                                 ; finish the line

    call allocate_recv_buffer               ; make a heap buffer big enough for the incoming bytes
    cmp rax, 0                              ; did allocation succeed
    jne .fail                               ; if not, stop now

; networking setup
    call create_socket                      ; ask Linux for a TCP socket
    cmp rax, 0                              ; negative return means syscall failure
    jl .fail                                ; abort if socket creation failed
    mov r12, rax                            ; keep the socket file descriptor in r12

    mov rdi, r12                            ; first argument = socket file descriptor
    call connect_to_server                  ; connect to the provided localhost server
    cmp rax, 0                              ; negative means connect failed
    jl .fail                                ; abort if the connection did not work

    mov rdi, r12                            ; pass the connected socket
    call discard_server_prompt              ; remove the welcome text so it does not mix with random data
    cmp rax, 0                              ; 0 means the prompt was cleared successfully
    jne .fail                               ; abort if startup text handling failed

    mov rdi, r12                            ; pass the same connected socket
    call send_request                       ; send the byte request string such as 2FF
    cmp rax, 0                              ; negative means the write failed
    jl .fail                                ; abort on send failure

    mov rdi, r12                            ; pass the socket to the receive routine
    call receive_data                       ; fill the heap buffer with the server's random bytes
    mov r13, rax                            ; keep the actual byte count returned by receive_data

    cmp r13, [rel requested_bytes]          ; make sure we got exactly what we asked for
    jne .fail                               ; partial data counts as failure here

; file setup
    call create_output_file                 ; create or truncate output.txt
    cmp rax, 0                              ; negative means open/create failed
    jl .fail                                ; abort if the file could not be opened
    mov r14, rax                            ; keep the output file descriptor in r14

; write the original random bytes first
    mov rdi, r14                            ; arg 1 = output file descriptor
    mov rsi, [rel recv_buffer]              ; arg 2 = pointer to the received bytes
    mov rdx, r13                            ; arg 3 = number of bytes to write
    call write_random_section               ; write header + raw bytes + newline
    cmp rax, 0                              ; 0 means the write worked
    jne .fail                               ; anything else means something went wrong

; sort the same buffer in memory
    mov rdi, [rel recv_buffer]              ; arg 1 = pointer to the buffer we want to sort
    mov rsi, r13                            ; arg 2 = number of bytes in that buffer
    call selection_sort                     ; sort the bytes in place

; write the sorted copy after the original section
    mov rdi, r14                            ; arg 1 = output file descriptor
    mov rsi, [rel recv_buffer]              ; arg 2 = pointer to the now-sorted buffer
    mov rdx, r13                            ; arg 3 = same byte count as before
    call write_sorted_section               ; write header + sorted bytes + newline
    cmp rax, 0                              ; 0 means the write worked
    jne .fail                               ; anything else means failure

; normal cleanup path
    mov rdi, r14                            ; pass the output file descriptor
    call close_output_file                  ; close output.txt cleanly
    cmp rax, 0                              ; make sure close worked too
    jne .fail_after_file_close              ; if not, fall into failure exit
    mov r14, -1                             ; mark the file as already closed

    mov rdi, r12                            ; socket fd for the close syscall
    mov rax, 3                              ; Linux syscall: close
    syscall                                 ; close the socket
    mov r12, -1                             ; mark the socket as already closed

    call release_recv_buffer                ; free the heap buffer before leaving

    mov rax, 1                              ; Linux syscall: write
    mov rdi, 1                              ; stdout
    lea rsi, [rel success_msg]              ; pointer to the success text
    mov rdx, success_msg_len                ; number of bytes to print
    syscall                                 ; show the success message

    mov rax, 60                             ; Linux syscall: exit
    xor rdi, rdi                            ; return code 0 = success
    syscall                                 ; end the program

.fail_after_file_close:
    mov r14, -1                             ; treat the file as already closed from here on

.fail:
    cmp r14, -1                             ; is there still an open file to close
    je .skip_file_close                     ; if not, skip file cleanup
    mov rdi, r14                            ; pass the file descriptor
    call close_output_file                  ; best-effort file close during failure cleanup
    mov r14, -1                             ; mark file as closed

.skip_file_close:
    cmp r12, -1                             ; is there still an open socket to close
    je .skip_socket_close                   ; if not, skip socket cleanup
    mov rdi, r12                            ; pass the socket file descriptor
    mov rax, 3                              ; Linux syscall: close
    syscall                                 ; close the socket if it is still open
    mov r12, -1                             ; mark socket as closed

.skip_socket_close:
    call release_recv_buffer                ; always try to free the heap buffer before exiting

    mov rax, 60                             ; Linux syscall: exit
    mov rdi, 1                              ; return code 1 = failure
    syscall                                 ; end the program with an error status


; build_request_hex
; Turns requested_bytes into a 3-character uppercase hex string
; Example: 0x3A7 becomes "3A7"
build_request_hex:
    mov rbx, [rel requested_bytes]          ; load the numeric request value

    mov rax, rbx                            ; copy the full value so we can isolate the first digit
    shr rax, 8                              ; move the top nibble down into the low 4 bits
    and al, 0x0F                            ; keep only that nibble
    call nibble_to_ascii                    ; convert 0-15 into its ASCII hex character
    mov [rel request_hex], al               ; store the first printable digit

    mov rax, rbx                            ; reload the original value for the middle digit
    shr rax, 4                              ; move the middle nibble down
    and al, 0x0F                            ; keep only that nibble
    call nibble_to_ascii                    ; convert it to ASCII
    mov [rel request_hex + 1], al           ; store the second printable digit

    mov rax, rbx                            ; reload the original value for the last digit
    and al, 0x0F                            ; keep the bottom nibble
    call nibble_to_ascii                    ; convert it to ASCII
    mov [rel request_hex + 2], al           ; store the third printable digit

    ret                                     ; return to the caller


; nibble_to_ascii
; Input:  AL = value from 0 to 15
; Output: AL = matching ASCII hex character
nibble_to_ascii:
    cmp al, 9                               ; 0-9 stay numeric, 10-15 become letters
    jbe .digit                              ; if AL is 9 or lower, jump to the digit path
    add al, 'A' - 10                        ; 10 -> A, 11 -> B, and so on
    ret                                     ; return with the letter in AL

.digit:
    add al, '0'                             ; 0 -> '0', 1 -> '1', and so on
    ret                                     ; return with the digit in AL

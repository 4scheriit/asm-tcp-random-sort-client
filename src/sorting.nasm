; ITSC204 Computer Architecture Final Project
; File: sorting.nasm
; Group members: Maxwell Brown, Filippo Cocco, Daniel Paetkau
; Description:
; Selection sort procedure for the TCP client.
; Handles sorting the random data received
; from the server before it is written to the file.

global selection_sort

section .data
    ; sorting constants here

section .bss
    ; sorting variables / buffers here

section .text

selection_sort:
    ; selection sort data
    ret
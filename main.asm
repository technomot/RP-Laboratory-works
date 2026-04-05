INCLUDELIB kernel32.lib
INCLUDELIB user32.lib
INCLUDELIB msvcrt.lib

EXTERN GetStdHandle   : PROC
EXTERN WriteConsoleA  : PROC
EXTERN ReadConsoleA   : PROC
EXTERN MessageBoxA    : PROC
EXTERN ExitProcess    : PROC
EXTERN wsprintfA      : PROC

.DATA

msg_a       BYTE "Enter a: ", 0
msg_d       BYTE "Enter d: ", 0
msg_c       BYTE "Enter c: ", 0

fmt_result  BYTE "Formula: 64*d / (c*a)", 13, 10,
            "a = %I64d", 13, 10,
            "d = %I64d", 13, 10,
            "c = %I64d", 13, 10,
            "Result = %I64d", 13, 10,
            "Execution time: %I64d cycles", 0

title_box   BYTE "Variant 6 - Result", 0

result_buf  BYTE 512 DUP(0)

buf_a       BYTE 32 DUP(0)
buf_d       BYTE 32 DUP(0)
buf_c       BYTE 32 DUP(0)

var_a       QWORD 0
var_d       QWORD 0
var_c       QWORD 0
var_result  QWORD 0
time_start  QWORD 0
time_end    QWORD 0
time_diff   QWORD 0
bytes_read  QWORD 0

.CODE

PrintStr PROC
    sub     rsp, 40
    mov     r8,  rdx
    mov     rdx, rcx
    mov     rcx, -11
    call    GetStdHandle
    mov     rcx, rax
    lea     r9,  bytes_read
    mov     QWORD PTR [rsp+32], 0
    call    WriteConsoleA
    add     rsp, 40
    ret
PrintStr ENDP

ReadStr PROC
    sub     rsp, 40
    mov     r8,  rdx
    mov     rdx, rcx
    mov     rcx, -10
    call    GetStdHandle
    mov     rcx, rax
    lea     r9,  bytes_read
    mov     QWORD PTR [rsp+32], 0
    call    ReadConsoleA
    mov     rax, bytes_read
    add     rsp, 40
    ret
ReadStr ENDP

AtoI64 PROC
    xor     rax, rax
    xor     rdx, rdx
    mov     r8,  rcx
    movzx   r9d, BYTE PTR [r8]
    cmp     r9b, '-'
    jne     AtoI64Loop
    mov     rdx, 1
    inc     r8
AtoI64Loop:
    movzx   r9d, BYTE PTR [r8]
    cmp     r9b, '0'
    jl      AtoI64Done
    cmp     r9b, '9'
    jg      AtoI64Done
    imul    rax, rax, 10
    sub     r9d, '0'
    add     rax, r9
    inc     r8
    jmp     AtoI64Loop
AtoI64Done:
    test    rdx, rdx
    jz      AtoI64Pos
    neg     rax
AtoI64Pos:
    ret
AtoI64 ENDP

main PROC
    sub     rsp, 88

    lea     rcx, msg_a
    mov     rdx, 9
    call    PrintStr

    lea     rcx, buf_a
    mov     rdx, 32
    call    ReadStr

    lea     rcx, buf_a
    call    AtoI64
    mov     var_a, rax

    lea     rcx, msg_d
    mov     rdx, 9
    call    PrintStr

    lea     rcx, buf_d
    mov     rdx, 32
    call    ReadStr

    lea     rcx, buf_d
    call    AtoI64
    mov     var_d, rax

    lea     rcx, msg_c
    mov     rdx, 9
    call    PrintStr

    lea     rcx, buf_c
    mov     rdx, 32
    call    ReadStr

    lea     rcx, buf_c
    call    AtoI64
    mov     var_c, rax

    rdtsc
    shl     rdx, 32
    or      rax, rdx
    mov     time_start, rax

    mov     rax, var_d
    shl     rax, 6

    mov     rbx, var_c
    imul    rbx, var_a

    test    rbx, rbx
    jz      MainDivZero

    cqo
    idiv    rbx
    mov     var_result, rax
    jmp     MainCalcDone

MainDivZero:
    mov     var_result, 0

MainCalcDone:

    rdtsc
    shl     rdx, 32
    or      rax, rdx
    mov     time_end, rax

    mov     rax, time_end
    sub     rax, time_start
    mov     time_diff, rax

    sub     rsp, 64

    lea     rcx, result_buf
    lea     rdx, fmt_result

    mov     r8,  var_a
    mov     r9,  var_d
    mov     rax, var_c
    mov     QWORD PTR [rsp+32], rax
    mov     rax, var_result
    mov     QWORD PTR [rsp+40], rax
    mov     rax, time_diff
    mov     QWORD PTR [rsp+48], rax

    call    wsprintfA

    add     rsp, 64

    sub     rsp, 32
    xor     rcx, rcx
    lea     rdx, result_buf
    lea     r8,  title_box
    xor     r9,  r9
    call    MessageBoxA
    add     rsp, 32

    xor     rcx, rcx
    call    ExitProcess

    add     rsp, 88
    ret
main ENDP

END
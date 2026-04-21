OPTION CASEMAP:NONE

EXTERN MessageBoxA   : PROC
EXTERN ExitProcess   : PROC
EXTERN GetStdHandle  : PROC
EXTERN WriteConsoleA : PROC
EXTERN ReadConsoleA  : PROC

STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11

.DATA

szCapCPU    DB  "CPUID - AVX/AVX2 Check", 0
szBothOK    DB  "AVX  : SUPPORTED", 13, 10,
                "AVX2 : SUPPORTED", 13, 10, 13, 10,
                "Group: KH-923i | Mahammad Mammadov", 0
szAVXonly   DB  "AVX  : SUPPORTED", 13, 10,
                "AVX2 : NOT SUPPORTED", 13, 10, 13, 10,
                "Group: KH-923i | Mahammad Mammadov", 0
szNoAVX     DB  "AVX  : NOT SUPPORTED", 13, 10,
                "AVX2 : NOT SUPPORTED", 13, 10,
                "SSE will be used.", 13, 10, 13, 10,
                "Group: KH-923i | Mahammad Mammadov", 0

szInfCap    DB  "INJECTED CODE", 0
szInfected  DB  "Infected | KH-923i | Mahammad Mammadov", 0

szCapInfo   DB  "Lab Work - Variant 6", 0
szInfo      DB  "Lab: Formula Calculation", 13, 10,
                "Formula: a * sqrt(c*e) - b*d", 13, 10,
                "Variant: 6", 13, 10,
                "Group:   KH-923i", 13, 10,
                "Author:  Mahammad Mammadov", 0

szCapRes    DB  "Result | Variant 6 | KH-923i | Mahammad Mammadov", 0
szPromptA   DB  "Enter a: ", 0
szPromptB   DB  "Enter b: ", 0
szPromptC   DB  "Enter c: ", 0
szPromptD   DB  "Enter d: ", 0
szPromptE   DB  "Enter e: ", 0
szResultLbl DB  "Result = ", 0
szFormula   DB  "Formula: a * sqrt(c*e) - b*d", 13, 10, 0
szCRLF      DB  13, 10, 0

szMsgBuf    DB  512 DUP(0)
szA         DB  32  DUP(0)
szB         DB  32  DUP(0)
szC         DB  32  DUP(0)
szD         DB  32  DUP(0)
szE         DB  32  DUP(0)
szRes       DB  32  DUP(0)
inputBuf    DB  64  DUP(0)
tmpBuf      DB  32  DUP(0)

ALIGN 8
valA        DQ  0.0
valB        DQ  0.0
valC        DQ  0.0
valD        DQ  0.0
valE        DQ  0.0
result      DQ  0.0
dbl10       DQ  10.0
dbl05       DQ  0.5
tmpInt      DQ  0

hStdin      DQ  0
hStdout     DQ  0
dwRead      DD  0

.CODE

PrintStr PROC
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48
    push    rbx
    push    r14

    mov     rbx, rcx
    xor     r14, r14

PS_count:
    cmp     BYTE PTR [rbx + r14], 0
    je      PS_send
    inc     r14
    jmp     PS_count

PS_send:
    mov     rcx, QWORD PTR [hStdout]
    mov     rdx, rbx
    mov     r8,  r14
    lea     r9,  dwRead
    mov     QWORD PTR [rsp+32], 0
    call    WriteConsoleA

    pop     r14
    pop     rbx
    add     rsp, 48
    pop     rbp
    ret
PrintStr ENDP

AppendStr PROC
AS_loop:
    mov     al, BYTE PTR [rsi]
    cmp     al, 0
    je      AS_done
    mov     BYTE PTR [rdi + r15], al
    inc     rsi
    inc     r15
    jmp     AS_loop
AS_done:
    ret
AppendStr ENDP

IntToStr PROC
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48
    push    rbx
    push    rsi
    push    rdi
    push    r14
    push    r15

    mov     rdi, rcx
    mov     rbx, rax
    lea     rsi, tmpBuf
    xor     r14, r14

    cmp     rbx, 0
    jne     ITS_loop
    mov     BYTE PTR [rsi], '0'
    mov     r14, 1
    jmp     ITS_reverse

ITS_loop:
    cmp     rbx, 0
    je      ITS_reverse
    xor     rdx, rdx
    mov     rax, rbx
    mov     r15, 10
    div     r15
    mov     rbx, rax
    add     dl, '0'
    mov     BYTE PTR [rsi + r14], dl
    inc     r14
    jmp     ITS_loop

ITS_reverse:
    xor     r15, r15
ITS_rev:
    cmp     r15, r14
    jge     ITS_done
    mov     rax, r14
    dec     rax
    sub     rax, r15
    movzx   eax, BYTE PTR [rsi + rax]
    mov     BYTE PTR [rdi + r15], al
    inc     r15
    jmp     ITS_rev

ITS_done:
    mov     BYTE PTR [rdi + r14], 0

    pop     r15
    pop     r14
    pop     rdi
    pop     rsi
    pop     rbx
    add     rsp, 48
    pop     rbp
    ret
IntToStr ENDP


DoubleToStr PROC
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48
    push    rbx
    push    rdi
    push    r14
    push    r15

    mov     rdi, rcx
    xor     r15, r15

    vxorpd      xmm1, xmm1, xmm1
    vcomisd     xmm0, xmm1
    jae         DTS_pos
    mov         BYTE PTR [rdi], '-'
    inc         r15
    vsubsd      xmm0, xmm1, xmm0

DTS_pos:
    vcvttsd2si  rax, xmm0
    mov         QWORD PTR [tmpInt], rax
    lea         rcx, [rdi + r15]
    call        IntToStr

DTS_end:
    cmp     BYTE PTR [rdi + r15], 0
    je      DTS_dot
    inc     r15
    jmp     DTS_end

DTS_dot:
    mov     BYTE PTR [rdi + r15], '.'
    inc     r15

    vcvtsi2sd   xmm1, xmm1, QWORD PTR [tmpInt]
    vsubsd      xmm0, xmm0, xmm1
    lea         rax, dbl10
    vmovsd      xmm2, QWORD PTR [rax]
    vmulsd      xmm0, xmm0, xmm2
    vmulsd      xmm0, xmm0, xmm2
    vmulsd      xmm0, xmm0, xmm2
    vmulsd      xmm0, xmm0, xmm2
    lea         rax, dbl05
    vmovsd      xmm3, QWORD PTR [rax]
    vaddsd      xmm0, xmm0, xmm3
    vcvttsd2si  rax, xmm0

    xor     rdx, rdx
    mov     r14, 1000
    div     r14
    add     al, '0'
    mov     BYTE PTR [rdi + r15], al
    inc     r15
    mov     rax, rdx

    xor     rdx, rdx
    mov     r14, 100
    div     r14
    add     al, '0'
    mov     BYTE PTR [rdi + r15], al
    inc     r15
    mov     rax, rdx

    xor     rdx, rdx
    mov     r14, 10
    div     r14
    add     al, '0'
    mov     BYTE PTR [rdi + r15], al
    inc     r15

    add     dl, '0'
    mov     BYTE PTR [rdi + r15], dl
    inc     r15
    mov     BYTE PTR [rdi + r15], 0

    pop     r15
    pop     r14
    pop     rdi
    pop     rbx
    add     rsp, 48
    pop     rbp
    ret
DoubleToStr ENDP

StrToDouble PROC
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48
    push    rbx
    push    r15

    mov     rbx, rcx
    vxorpd      xmm0, xmm0, xmm0
    lea         rax, dbl10
    vmovsd      xmm3, QWORD PTR [rax]
    xor         r15, r15

    cmp     BYTE PTR [rbx], '-'
    jne     STD_int
    inc     rbx
    mov     r15, 1

STD_int:
    movzx   eax, BYTE PTR [rbx]
    cmp     al, '.'
    je      STD_frac_s
    cmp     al, 0
    je      STD_done
    cmp     al, 13
    je      STD_done
    cmp     al, 10
    je      STD_done
    sub     al, '0'
    vcvtsi2sd   xmm1, xmm1, eax
    vmulsd      xmm0, xmm0, xmm3
    vaddsd      xmm0, xmm0, xmm1
    inc     rbx
    jmp     STD_int

STD_frac_s:
    inc     rbx
    lea     rax, dbl10
    vmovsd  xmm2, QWORD PTR [rax]

STD_frac:
    movzx   eax, BYTE PTR [rbx]
    cmp     al, 0
    je      STD_done
    cmp     al, 13
    je      STD_done
    cmp     al, 10
    je      STD_done
    sub     al, '0'
    vcvtsi2sd   xmm1, xmm1, eax
    vdivsd      xmm1, xmm1, xmm2
    vaddsd      xmm0, xmm0, xmm1
    vmulsd      xmm2, xmm2, xmm3
    inc     rbx
    jmp     STD_frac

STD_done:
    cmp     r15, 1
    jne     STD_noneg
    vxorpd  xmm1, xmm1, xmm1
    vsubsd  xmm0, xmm1, xmm0

STD_noneg:
    pop     r15
    pop     rbx
    add     rsp, 48
    pop     rbp
    ret
StrToDouble ENDP

ReadDouble PROC
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48

    lea     rax, inputBuf
    mov     QWORD PTR [rax],    0
    mov     QWORD PTR [rax+8],  0
    mov     QWORD PTR [rax+16], 0
    mov     QWORD PTR [rax+24], 0
    mov     QWORD PTR [rax+32], 0
    mov     QWORD PTR [rax+40], 0
    mov     QWORD PTR [rax+48], 0
    mov     QWORD PTR [rax+56], 0

    mov     rcx, QWORD PTR [hStdin]
    lea     rdx, inputBuf
    mov     r8,  63
    lea     r9,  dwRead
    mov     QWORD PTR [rsp+32], 0
    call    ReadConsoleA

    lea     rcx, inputBuf
    call    StrToDouble

    add     rsp, 48
    pop     rbp
    ret
ReadDouble ENDP


main PROC
    push    rbp
    mov     rbp, rsp
    sub     rsp, 64

    ; GetStdHandle - STD_INPUT_HANDLE = -10
    mov     rcx, STD_INPUT_HANDLE
    call    GetStdHandle
    mov     QWORD PTR [hStdin], rax

    ; GetStdHandle - STD_OUTPUT_HANDLE = -11
    mov     rcx, STD_OUTPUT_HANDLE
    call    GetStdHandle
    mov     QWORD PTR [hStdout], rax

    ; ETAP 1: AVX/AVX2 check
    mov     eax, 1
    cpuid
    mov     r12d, ecx

    mov     eax, 7
    xor     ecx, ecx
    cpuid
    mov     r13d, ebx

    bt      r12d, 28
    jnc     avx_no

    bt      r13d, 5
    jnc     avx_only

    xor     rcx, rcx
    lea     rdx, szBothOK
    lea     r8,  szCapCPU
    xor     r9,  r9
    call    MessageBoxA
    jmp     nop_zone

avx_only:
    xor     rcx, rcx
    lea     rdx, szAVXonly
    lea     r8,  szCapCPU
    xor     r9,  r9
    call    MessageBoxA
    jmp     nop_zone

avx_no:
    xor     rcx, rcx
    lea     rdx, szNoAVX
    lea     r8,  szCapCPU
    xor     r9,  r9
    call    MessageBoxA

    movsd   xmm2, QWORD PTR [valC]
    mulsd   xmm2, QWORD PTR [valE]
    sqrtsd  xmm2, xmm2
    movsd   xmm0, QWORD PTR [valA]
    mulsd   xmm0, xmm2
    movsd   xmm1, QWORD PTR [valB]
    mulsd   xmm1, QWORD PTR [valD]
    subsd   xmm0, xmm1
    movsd   QWORD PTR [result], xmm0
    jmp     show_result

nop_zone:
    DB  128 DUP(90h)

    xor     rcx, rcx
    lea     rdx, szInfo
    lea     r8,  szCapInfo
    xor     r9,  r9
    call    MessageBoxA

    lea     rcx, szPromptA
    call    PrintStr
    call    ReadDouble
    lea     rax, valA
    vmovsd  QWORD PTR [rax], xmm0

    lea     rcx, szPromptB
    call    PrintStr
    call    ReadDouble
    lea     rax, valB
    vmovsd  QWORD PTR [rax], xmm0

    lea     rcx, szPromptC
    call    PrintStr
    call    ReadDouble
    lea     rax, valC
    vmovsd  QWORD PTR [rax], xmm0

    lea     rcx, szPromptD
    call    PrintStr
    call    ReadDouble
    lea     rax, valD
    vmovsd  QWORD PTR [rax], xmm0

    lea     rcx, szPromptE
    call    PrintStr
    call    ReadDouble
    lea     rax, valE
    vmovsd  QWORD PTR [rax], xmm0

    lea     rax, valC
    vmovsd  xmm2, QWORD PTR [rax]
    lea     rax, valE
    vmulsd  xmm2, xmm2, QWORD PTR [rax]
    vsqrtsd xmm2, xmm2, xmm2

    lea     rax, valA
    vmovsd  xmm0, QWORD PTR [rax]
    vmulsd  xmm0, xmm0, xmm2

    lea     rax, valB
    vmovsd  xmm1, QWORD PTR [rax]
    lea     rax, valD
    vmulsd  xmm1, xmm1, QWORD PTR [rax]

    vsubsd  xmm0, xmm0, xmm1
    lea     rax, result
    vmovsd  QWORD PTR [rax], xmm0
    vzeroupper

show_result:
    lea     rcx, szA
    movsd   xmm0, QWORD PTR [valA]
    call    DoubleToStr

    lea     rcx, szB
    movsd   xmm0, QWORD PTR [valB]
    call    DoubleToStr

    lea     rcx, szC
    movsd   xmm0, QWORD PTR [valC]
    call    DoubleToStr

    lea     rcx, szD
    movsd   xmm0, QWORD PTR [valD]
    call    DoubleToStr

    lea     rcx, szE
    movsd   xmm0, QWORD PTR [valE]
    call    DoubleToStr

    lea     rcx, szRes
    movsd   xmm0, QWORD PTR [result]
    call    DoubleToStr

    lea     rdi, szMsgBuf
    xor     r15, r15

    lea     rsi, szPromptA
    call    AppendStr
    lea     rsi, szA
    call    AppendStr
    lea     rsi, szCRLF
    call    AppendStr

    lea     rsi, szPromptB
    call    AppendStr
    lea     rsi, szB
    call    AppendStr
    lea     rsi, szCRLF
    call    AppendStr

    lea     rsi, szPromptC
    call    AppendStr
    lea     rsi, szC
    call    AppendStr
    lea     rsi, szCRLF
    call    AppendStr

    lea     rsi, szPromptD
    call    AppendStr
    lea     rsi, szD
    call    AppendStr
    lea     rsi, szCRLF
    call    AppendStr

    lea     rsi, szPromptE
    call    AppendStr
    lea     rsi, szE
    call    AppendStr
    lea     rsi, szCRLF
    call    AppendStr
    lea     rsi, szCRLF
    call    AppendStr

    lea     rsi, szFormula
    call    AppendStr

    lea     rsi, szResultLbl
    call    AppendStr
    lea     rsi, szRes
    call    AppendStr

    mov     BYTE PTR [rdi + r15], 0

    xor     rcx, rcx
    lea     rdx, szMsgBuf
    lea     r8,  szCapRes
    xor     r9,  r9
    call    MessageBoxA

    add     rsp, 64
    pop     rbp
    xor     ecx, ecx
    call    ExitProcess

main ENDP
END
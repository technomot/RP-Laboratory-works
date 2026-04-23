OPTION CASEMAP:NONE

EXTERN MessageBoxIndirectA : PROC
EXTERN ExitProcess         : PROC
EXTERN GetStdHandle        : PROC
EXTERN WriteConsoleA       : PROC
EXTERN ReadConsoleA        : PROC

STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11


.DATA
szPassword      DB  "KH923i", 0
szCapPwd        DB  "Password Check", 0
szPwdPrompt     DB  "Enter password: ", 0
szPwdOK         DB  "Password correct! Access granted.", 0
szPwdFail       DB  "Wrong password! Access denied.", 0

szCapCPU        DB  "CPUID - AVX/AVX2 Check", 0
szBothOK        DB  "AVX  : SUPPORTED", 13, 10,
                    "AVX2 : SUPPORTED", 13, 10, 13, 10,
                    "Group: KH-923i | Mahammad Mammadov", 0
szAVXonly       DB  "AVX  : SUPPORTED", 13, 10,
                    "AVX2 : NOT SUPPORTED", 13, 10, 13, 10,
                    "Group: KH-923i | Mahammad Mammadov", 0
szNoAVX         DB  "AVX  : NOT SUPPORTED", 13, 10,
                    "AVX2 : NOT SUPPORTED", 13, 10,
                    "SSE will be used.", 13, 10, 13, 10,
                    "Group: KH-923i | Mahammad Mammadov", 0


szCapInfo       DB  "Lab Work 5 - Variant 6", 0
szInfo          DB  "Lab: Formula with AVX", 13, 10,
                    "Formula: sqrt(a*b) + c/d/e", 13, 10,
                    "Variant: 6", 13, 10,
                    "Group:   KH-923i", 13, 10,
                    "Author:  Mahammad Mammadov", 0


szPromptA1      DB  "Enter a[0]: ", 0
szPromptA2      DB  "Enter a[1]: ", 0
szPromptA3      DB  "Enter a[2]: ", 0
szPromptA4      DB  "Enter a[3]: ", 0
szPromptA5      DB  "Enter a[4]: ", 0
szPromptB       DB  "Enter b: ", 0
szPromptC       DB  "Enter c: ", 0
szPromptD       DB  "Enter d: ", 0
szPromptE       DB  "Enter e: ", 0


szCapRes        DB  "Result | Variant 6 | KH-923i | Mahammad Mammadov", 0


szCRLF          DB  13, 10, 0
szResultLbl     DB  "Result[", 0
szResultMid     DB  "]: sqrt(a*b) + c/d/e = ", 0


szMsgBuf        DB  1024 DUP(0)
szTmpA          DB  32   DUP(0)
szTmpR          DB  32   DUP(0)
szIdxBuf        DB  4    DUP(0)
inputBuf        DB  64   DUP(0)
tmpBuf          DB  32   DUP(0)
pwdBuf          DB  32   DUP(0)


ALIGN 8
arrA            DQ  0.0, 0.0, 0.0, 0.0, 0.0
valB            DQ  0.0
valC            DQ  0.0
valD            DQ  0.0
valE            DQ  0.0
arrResult       DQ  0.0, 0.0, 0.0, 0.0, 0.0

dbl10           DQ  10.0
dbl05           DQ  0.5
tmpInt          DQ  0

hStdin          DQ  0
hStdout         DQ  0
dwRead          DD  0


ALIGN 8
mbParams        DD  72          ; cbSize
                DD  0           ; padding
                DQ  0           ; hwndOwner
                DQ  0           ; hInstance
                DQ  0           ; lpszText  (filled at runtime)
                DQ  0           ; lpszCaption (filled at runtime)
                DD  0           ; dwStyle MB_OK
                DD  0           ; padding
                DQ  0           ; lpszIcon
                DQ  0           ; dwContextHelpId
                DQ  0           ; lpfnMsgBoxCallback
                DD  0           ; dwLanguageId
                DD  0           ; padding

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

ReadLine PROC
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48

    lea     rax, pwdBuf
    mov     QWORD PTR [rax],    0
    mov     QWORD PTR [rax+8],  0
    mov     QWORD PTR [rax+16], 0
    mov     QWORD PTR [rax+24], 0

    mov     rcx, QWORD PTR [hStdin]
    lea     rdx, pwdBuf
    mov     r8,  31
    lea     r9,  dwRead
    mov     QWORD PTR [rsp+32], 0
    call    ReadConsoleA

    
    lea     rbx, pwdBuf
    xor     r14, r14
RL_trim:
    mov     al, BYTE PTR [rbx + r14]
    cmp     al, 13
    je      RL_zero
    cmp     al, 10
    je      RL_zero
    cmp     al, 0
    je      RL_done
    inc     r14
    jmp     RL_trim
RL_zero:
    mov     BYTE PTR [rbx + r14], 0
RL_done:
    add     rsp, 48
    pop     rbp
    ret
ReadLine ENDP


CompareStr PROC
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32
    push    rbx
    push    r14

    mov     rbx, rcx
    mov     r14, rdx
    xor     r15, r15

CS_loop:
    movzx   eax, BYTE PTR [rbx + r15]
    movzx   ecx, BYTE PTR [r14 + r15]
    cmp     al, cl
    jne     CS_notequal
    cmp     al, 0
    je      CS_equal
    inc     r15
    jmp     CS_loop

CS_equal:
    xor     rax, rax
    jmp     CS_done

CS_notequal:
    mov     rax, 1

CS_done:
    pop     r14
    pop     rbx
    add     rsp, 32
    pop     rbp
    ret
CompareStr ENDP


ShowMsgIndirect PROC
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32

    
    lea     rax, mbParams
    mov     QWORD PTR [rax+24], rcx

    
    mov     QWORD PTR [rax+32], rdx

    
    lea     rcx, mbParams
    call    MessageBoxIndirectA

    add     rsp, 32
    pop     rbp
    ret
ShowMsgIndirect ENDP


main PROC
    push    rbp
    mov     rbp, rsp
    sub     rsp, 64

    ; get console handles
    mov     rcx, STD_INPUT_HANDLE
    call    GetStdHandle
    mov     QWORD PTR [hStdin], rax

    mov     rcx, STD_OUTPUT_HANDLE
    call    GetStdHandle
    mov     QWORD PTR [hStdout], rax

    
    lea     rcx, szPwdPrompt
    call    PrintStr
    call    ReadLine

    lea     rcx, pwdBuf
    lea     rdx, szPassword
    call    CompareStr

    cmp     rax, 0
    je      pwd_ok

    
    lea     rcx, szPwdFail
    lea     rdx, szCapPwd
    call    ShowMsgIndirect
    jmp     exit_prog

pwd_ok:
    lea     rcx, szPwdOK
    lea     rdx, szCapPwd
    call    ShowMsgIndirect

    
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

    lea     rcx, szBothOK
    lea     rdx, szCapCPU
    call    ShowMsgIndirect
    jmp     avx_done

avx_only:
    lea     rcx, szAVXonly
    lea     rdx, szCapCPU
    call    ShowMsgIndirect
    jmp     avx_done

avx_no:
    lea     rcx, szNoAVX
    lea     rdx, szCapCPU
    call    ShowMsgIndirect

avx_done:

    
    lea     rcx, szInfo
    lea     rdx, szCapInfo
    call    ShowMsgIndirect

    
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

    
    xor     r15, r15        ; i = 0

input_loop:
    cmp     r15, 5
    jge     input_done

    ; print prompt for a[i]
    cmp     r15, 0
    jne     try1
    lea     rcx, szPromptA1
    call    PrintStr
    jmp     do_read
try1:
    cmp     r15, 1
    jne     try2
    lea     rcx, szPromptA2
    call    PrintStr
    jmp     do_read
try2:
    cmp     r15, 2
    jne     try3
    lea     rcx, szPromptA3
    call    PrintStr
    jmp     do_read
try3:
    cmp     r15, 3
    jne     try4
    lea     rcx, szPromptA4
    call    PrintStr
    jmp     do_read
try4:
    lea     rcx, szPromptA5
    call    PrintStr

do_read:
    call    ReadDouble

    
    lea     rax, arrA
    vmovsd  QWORD PTR [rax + r15*8], xmm0

    
    lea     rax, valB
    vmovsd  xmm1, QWORD PTR [rax]
    vmulsd  xmm0, xmm0, xmm1       

    vsqrtsd xmm0, xmm0, xmm0       

    lea     rax, valC
    vmovsd  xmm1, QWORD PTR [rax]
    lea     rax, valD
    vmovsd  xmm2, QWORD PTR [rax]
    vdivsd  xmm1, xmm1, xmm2       

    lea     rax, valE
    vmovsd  xmm2, QWORD PTR [rax]
    vdivsd  xmm1, xmm1, xmm2       

    vaddsd  xmm0, xmm0, xmm1       

    lea     rax, arrResult
    vmovsd  QWORD PTR [rax + r15*8], xmm0

    inc     r15
    jmp     input_loop

input_done:
    vzeroupper

    lea     rdi, szMsgBuf
    xor     r15, r15

    xor     r14, r14        ; i = 0

result_loop:
    cmp     r14, 5
    jge     result_done

    lea     rsi, szResultLbl
    call    AppendStr

    
    mov     rax, r14
    add     al, '0'
    mov     BYTE PTR [rdi + r15], al
    inc     r15

    lea     rsi, szResultMid
    call    AppendStr

   
    lea     rcx, szTmpR
    lea     rax, arrResult
    vmovsd  xmm0, QWORD PTR [rax + r14*8]
    call    DoubleToStr
    lea     rsi, szTmpR
    call    AppendStr

    lea     rsi, szCRLF
    call    AppendStr

    inc     r14
    jmp     result_loop

result_done:
    mov     BYTE PTR [rdi + r15], 0

    lea     rcx, szMsgBuf
    lea     rdx, szCapRes
    call    ShowMsgIndirect

exit_prog:
    add     rsp, 64
    pop     rbp
    xor     ecx, ecx
    call    ExitProcess

main ENDP
END
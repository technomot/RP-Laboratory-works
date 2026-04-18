OPTION CASEMAP:NONE

EXTERN MessageBoxA : PROC
EXTERN wsprintfA   : PROC
EXTERN ExitProcess : PROC

.DATA

szCap       DB  "CPUID - AVX/AVX2 Check", 0

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

szCapInfo   DB  "Lab Work - Variant 6", 0
szInfo      DB  "Lab: Arrays - VPMULHW", 13, 10,
                "Instruction: VPMULHW", 13, 10,
                "Variant: 6", 13, 10,
                "Group:   KH-923i", 13, 10,
                "Author:  Mahammad Mammadov", 0

szInfCap    DB  "INJECTED CODE", 0
szInfected  DB  "Infected | KH-923i | Mahammad Mammadov", 0

szCapRes    DB  "VPMULHW | Variant 6 | KH-923i | Mahammad Mammadov", 0

szFmt       DB  "i = %d", 13, 10,
                "A[i]       = %d", 13, 10,
                "B[i]       = %d", 13, 10,
                "A[i]*B[i]  = %d", 13, 10,
                "VPMULHW[i] = %d", 0

szBuf       DB  512 DUP(0)

arrayA      DW  100,  200,  300,  400,  500,
                600,  700,  800,  900, 1000,
                0, 0, 0, 0, 0, 0

arrayB      DW  200,  300,  100,  500,  400,
                700,  600,  800, 1000,  900,
                0, 0, 0, 0, 0, 0

arrayR      DW  16 DUP(0)

nIdx        DD  0
nA          DD  0
nB          DD  0
nFull       DD  0
nHigh       DD  0

.CODE

main PROC
    push    rbp
    mov     rbp, rsp
    sub     rsp, 64

    

    mov     eax, 1
    cpuid
    mov     r12d, ecx

    mov     eax, 7
    xor     ecx, ecx
    cpuid
    mov     r13d, ebx

    bt      r12d, 28
    jnc     no_avx

    bt      r13d, 5
    jnc     avx_only

    xor     rcx, rcx
    lea     rdx, szBothOK
    lea     r8,  szCap
    xor     r9,  r9
    call    MessageBoxA
    jmp     nop_zone

avx_only:
    xor     rcx, rcx
    lea     rdx, szAVXonly
    lea     r8,  szCap
    xor     r9,  r9
    call    MessageBoxA
    jmp     nop_zone

no_avx:
    xor     rcx, rcx
    lea     rdx, szNoAVX
    lea     r8,  szCap
    xor     r9,  r9
    call    MessageBoxA

   
nop_zone:
    DB  128 DUP(90h)

    ; --- INFO ---
    xor     rcx, rcx
    lea     rdx, szInfo
    lea     r8,  szCapInfo
    xor     r9,  r9
    call    MessageBoxA

   

    lea     rax, arrayA
    vmovdqu ymm0, YMMWORD PTR [rax]

    lea     rax, arrayB
    vmovdqu ymm1, YMMWORD PTR [rax]

    vpmulhw ymm2, ymm0, ymm1

    lea     rax, arrayR
    vmovdqu YMMWORD PTR [rax], ymm2

    vzeroupper

    xor     r15, r15

loop_print:
    cmp     r15d, 10
    jge     loop_done

    mov     DWORD PTR [nIdx], r15d

    lea     rax, arrayA
    movsx   eax, WORD PTR [rax + r15*2]
    mov     DWORD PTR [nA], eax

    lea     rax, arrayB
    movsx   eax, WORD PTR [rax + r15*2]
    mov     DWORD PTR [nB], eax

    lea     rax, arrayR
    movsx   eax, WORD PTR [rax + r15*2]
    mov     DWORD PTR [nHigh], eax

    lea     rax, arrayA
    movsx   eax, WORD PTR [rax + r15*2]
    lea     rcx, arrayB
    movsx   ecx, WORD PTR [rcx + r15*2]
    imul    eax, ecx
    mov     DWORD PTR [nFull], eax

    lea     rcx, szBuf
    lea     rdx, szFmt
    mov     r8d,  DWORD PTR [nIdx]
    mov     r9d,  DWORD PTR [nA]
    mov     eax,  DWORD PTR [nB]
    mov     DWORD PTR [rsp+32], eax
    mov     eax,  DWORD PTR [nFull]
    mov     DWORD PTR [rsp+40], eax
    mov     eax,  DWORD PTR [nHigh]
    mov     DWORD PTR [rsp+48], eax
    call    wsprintfA

    xor     rcx, rcx
    lea     rdx, szBuf
    lea     r8,  szCapRes
    xor     r9,  r9
    call    MessageBoxA

    inc     r15
    jmp     loop_print

loop_done:
    add     rsp, 64
    pop     rbp
    xor     ecx, ecx
    call    ExitProcess

main ENDP
END
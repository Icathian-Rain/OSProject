; Disassembly of file: .\schedule.o
; Thu Feb 23 10:20:46 2023
; Type: COFF32
; Syntax: NASM
; Instruction set: 80386


global _TaskPriority
global _LeftTicks
global _RunningTask
global _main: function

extern ___main                                          ; near


SECTION .text   align=4 execute                         ; section number 1, code


SECTION .data   align=4 noexecute                       ; section number 2, data

_TaskPriority:                                          ; dword
        dd 00000008H                                    ; 0000 _ 8 

?_001:  dd 00000006H                                    ; 0004 _ 6 

?_002:  dd 00000004H                                    ; 0008 _ 4 

?_003:  dd 00000002H                                    ; 000C _ 2 


SECTION .bss    align=4 noexecute                       ; section number 3, bss

_LeftTicks:                                             ; dword
        resd    1                                       ; 0000

?_004:  resd    1                                       ; 0004

?_005:  resd    1                                       ; 0008

?_006:  resd    1                                       ; 000C

_RunningTask:                                           ; dword
        resd    1                                       ; 0010


SECTION .text.startup align=16 execute                  ; section number 4, code

.text.startup:; Local function

_main:
        push    ebp                                     ; 0000 _ 55
        mov     ebp, esp                                ; 0001 _ 89. E5
        push    esi                                     ; 0003 _ 56
        push    ebx                                     ; 0004 _ 53
        and     esp, 0FFFFFFF0H                         ; 0005 _ 83. E4, F0
        call    ___main                                 ; 0008 _ E8, 00000000(rel)
        mov     edx, dword [_RunningTask]               ; 000D _ 8B. 15, 00000010(d)
        mov     ecx, dword [_LeftTicks+edx*4]           ; 0013 _ 8B. 0C 95, 00000000(d)
        test    ecx, ecx                                ; 001A _ 85. C9
        jnz     ?_010                                   ; 001C _ 75, 4C
        mov     eax, dword [_LeftTicks]                 ; 001E _ A1, 00000000(d)
        mov     ebx, edx                                ; 0023 _ 89. D3
        or      eax, dword [?_004]                      ; 0025 _ 0B. 05, 00000004(d)
        or      eax, dword [?_005]                      ; 002B _ 0B. 05, 00000008(d)
        or      eax, dword [?_006]                      ; 0031 _ 0B. 05, 0000000C(d)
        jz      ?_011                                   ; 0037 _ 74, 42
?_007:  xor     eax, eax                                ; 0039 _ 31. C0
        xor     esi, esi                                ; 003B _ 31. F6
?_008:  cmp     dword [_LeftTicks+eax*4], ecx           ; 003D _ 39. 0C 85, 00000000(d)
        jle     ?_009                                   ; 0044 _ 7E, 0E
        mov     ecx, dword [_TaskPriority+eax*4]        ; 0046 _ 8B. 0C 85, 00000000(d)
        mov     ebx, eax                                ; 004D _ 89. C3
        mov     esi, 1                                  ; 004F _ BE, 00000001
?_009:  add     eax, 1                                  ; 0054 _ 83. C0, 01
        cmp     eax, 4                                  ; 0057 _ 83. F8, 04
        jnz     ?_008                                   ; 005A _ 75, E1
        mov     eax, esi                                ; 005C _ 89. F0
        test    al, al                                  ; 005E _ 84. C0
        jz      ?_010                                   ; 0060 _ 74, 08
        mov     dword [_RunningTask], ebx               ; 0062 _ 89. 1D, 00000010(d)
        mov     edx, ebx                                ; 0068 _ 89. DA
?_010:  sub     dword [_LeftTicks+edx*4], 1             ; 006A _ 83. 2C 95, 00000000(d), 01
        lea     esp, [ebp-8H]                           ; 0072 _ 8D. 65, F8
        xor     eax, eax                                ; 0075 _ 31. C0
        pop     ebx                                     ; 0077 _ 5B
        pop     esi                                     ; 0078 _ 5E
        pop     ebp                                     ; 0079 _ 5D
        ret                                             ; 007A _ C3

?_011:  ; Local function
        mov     eax, dword [_TaskPriority]              ; 007B _ A1, 00000000(d)
        mov     dword [_LeftTicks], eax                 ; 0080 _ A3, 00000000(d)
        mov     eax, dword [?_001]                      ; 0085 _ A1, 00000004(d)
        mov     dword [?_004], eax                      ; 008A _ A3, 00000004(d)
        mov     eax, dword [?_002]                      ; 008F _ A1, 00000008(d)
        mov     dword [?_005], eax                      ; 0094 _ A3, 00000008(d)
        mov     eax, dword [?_003]                      ; 0099 _ A1, 0000000C(d)
        mov     dword [?_006], eax                      ; 009E _ A3, 0000000C(d)
        jmp     ?_007                                   ; 00A3 _ EB, 94

        nop                                             ; 00A5 _ 90
        nop                                             ; 00A6 _ 90
        nop                                             ; 00A7 _ 90
        nop                                             ; 00A8 _ 90
        nop                                             ; 00A9 _ 90
        nop                                             ; 00AA _ 90
        nop                                             ; 00AB _ 90
        nop                                             ; 00AC _ 90
        nop                                             ; 00AD _ 90
        nop                                             ; 00AE _ 90
        nop                                             ; 00AF _ 90


SECTION .rdata$zzz align=4 noexecute                    ; section number 5, const

        db 47H, 43H, 43H, 3AH, 20H, 28H, 78H, 38H       ; 0000 _ GCC: (x8
        db 36H, 5FH, 36H, 34H, 2DH, 77H, 69H, 6EH       ; 0008 _ 6_64-win
        db 33H, 32H, 2DH, 73H, 65H, 68H, 2DH, 72H       ; 0010 _ 32-seh-r
        db 65H, 76H, 30H, 2CH, 20H, 42H, 75H, 69H       ; 0018 _ ev0, Bui
        db 6CH, 74H, 20H, 62H, 79H, 20H, 4DH, 69H       ; 0020 _ lt by Mi
        db 6EH, 47H, 57H, 2DH, 57H, 36H, 34H, 20H       ; 0028 _ nGW-W64 
        db 70H, 72H, 6FH, 6AH, 65H, 63H, 74H, 29H       ; 0030 _ project)
        db 20H, 38H, 2EH, 31H, 2EH, 30H, 00H, 00H       ; 0038 _  8.1.0..



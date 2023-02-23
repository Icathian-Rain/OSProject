; ==========================================
; pmtest8.asm
; 编译方法：nasm pmtest8.asm -o pmtest8.com
; ==========================================

%include	"pm.inc"	; 常量, 宏, 以及一些说明

PageDirBase0		equ	200000h	; 页目录开始地址:	2M
PageTblBase0		equ	201000h	; 页表开始地址:		2M +  4K
PageDirBase1		equ	210000h	; 页目录开始地址:	2M + 64K
PageTblBase1		equ	211000h	; 页表开始地址:		2M + 64K + 4K
PageDirBase2		equ	220000h	; 页目录开始地址:	2M + 128K
PageTblBase2		equ	221000h	; 页表开始地址:		2M + 128K + 4K
PageDirBase3		equ	230000h	; 页目录开始地址:	2M + 192K
PageTblBase3		equ	231000h	; 页表开始地址:		2M + 192K + 4K
org	0100h
	jmp	LABEL_BEGIN

[SECTION .gdt]
; GDT
;                           段基址,       段界限, 属性
LABEL_GDT:          Descriptor 0,              0, 0                      ; 空描述符
LABEL_DESC_NORMAL:  Descriptor 0,         0ffffh, DA_DRW                 ; Normal 描述符
LABEL_DESC_FLAT_C:  Descriptor 0,        0fffffh, DA_CR|DA_32|DA_LIMIT_4K; 0~4G
LABEL_DESC_FLAT_RW: Descriptor 0,        0fffffh, DA_DRW|DA_LIMIT_4K     ; 0~4G
LABEL_DESC_CODE32:  Descriptor 0, SegCode32Len-1, DA_CR|DA_32            ; 非一致代码段, 32
LABEL_DESC_CODE16:  Descriptor 0,         0ffffh, DA_C                   ; 非一致代码段, 16

LABEL_DESC_CODE_SWITCH:  Descriptor 0,  SegCodeSwitchLen-1, DA_C+DA_32	   ;非一致,32
LABEL_DESC_CODE_EXIT:  Descriptor 0,  SegCodeExitLen-1, DA_C+DA_32	   ;非一致,32

LABEL_DESC_DATA:    Descriptor 0,      DataLen-1, DA_DRW                 ; Data
LABEL_DESC_STACK:   Descriptor 0,     TopOfStack, DA_DRWA|DA_32          ; Stack, 32 位
LABEL_DESC_STACK3:     Descriptor 0,       TopOfStack3, DA_DRWA+DA_32+DA_DPL3
LABEL_DESC_VIDEO:   Descriptor 0B8000h,   0ffffh, DA_DRW+DA_DPL3                 ; 显存首地址

; TSS
LABEL_DESC_TSS: 	Descriptor 			0,          TSSLen-1, DA_386TSS	   ;TSS
; 任务A的描述符
LABEL_TASKA_DESC_LDT:  Descriptor         0,   TASKALDTLen - 1, DA_LDT
; 任务B的描述符
LABEL_TASKB_DESC_LDT:  Descriptor         0,   TASKBLDTLen - 1, DA_LDT


; 门                                            目标选择子,       偏移, DCount, 属性
LABEL_CALL_GATE_SWITCH:	Gate		  SelectorCodeSwitch,          0,      0, DA_386CGate + DA_DPL3
LABEL_CALL_GATE_EXIT:	Gate		  SelectorCodeEXIT,          0,      0, DA_386CGate + DA_DPL3
; GDT 结束

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1	; GDT界限
		dd	0		; GDT基地址

; GDT 选择子
SelectorNormal		equ	LABEL_DESC_NORMAL	- LABEL_GDT
SelectorFlatC		equ	LABEL_DESC_FLAT_C	- LABEL_GDT
SelectorFlatRW		equ	LABEL_DESC_FLAT_RW	- LABEL_GDT
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorCode16		equ	LABEL_DESC_CODE16	- LABEL_GDT

SelectorCodeSwitch	equ	LABEL_DESC_CODE_SWITCH	- LABEL_GDT
SelectorCodeEXIT	equ	LABEL_DESC_CODE_EXIT	- LABEL_GDT

SelectorStack3		equ	LABEL_DESC_STACK3	- LABEL_GDT + SA_RPL3
SelectorData		equ	LABEL_DESC_DATA		- LABEL_GDT
SelectorStack		equ	LABEL_DESC_STACK	- LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT
; TSS
SelectorTSS        equ LABEL_DESC_TSS     		- LABEL_GDT
; 任务A的选择子
SelectorLDTA		equ LABEL_TASKA_DESC_LDT		- LABEL_GDT
; 任务B的选择子
SelectorLDTB		equ LABEL_TASKB_DESC_LDT		- LABEL_GDT

SelectorCallGateSwitch	equ	LABEL_CALL_GATE_SWITCH	- LABEL_GDT + SA_RPL3
SelectorCallGateExit	equ	LABEL_CALL_GATE_EXIT	- LABEL_GDT + SA_RPL3


; END of [SECTION .gdt]

[SECTION .data1]	 ; 数据段
ALIGN	32
[BITS	32]
LABEL_DATA:
; 实模式下使用这些符号
; 字符串
_szPMMessage:			db	"In Protect Mode now. ^-^", 0Ah, 0Ah, 0	; 进入保护模式后显示此字符串
_szMemChkTitle:			db	"BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0	; 进入保护模式后显示此字符串
_szRAMSize			db	"RAM size:", 0
_szReturn			db	0Ah, 0
; 变量
_wSPValueInRealMode		dw	0
_dwMCRNumber:			dd	0	; Memory Check Result
_dwDispPos:			dd	(80 * 6 + 0) * 2	; 屏幕第 6 行, 第 0 列。
_dwMemSize:			dd	0
_ARDStruct:			; Address Range Descriptor Structure
	_dwBaseAddrLow:		dd	0
	_dwBaseAddrHigh:	dd	0
	_dwLengthLow:		dd	0
	_dwLengthHigh:		dd	0
	_dwType:		dd	0
_PageTableNumber		dd	0

_MemChkBuf:	times	256	db	0

; 保护模式下使用这些符号
szPMMessage		equ	_szPMMessage	- $$
szMemChkTitle		equ	_szMemChkTitle	- $$
szRAMSize		equ	_szRAMSize	- $$
szReturn		equ	_szReturn	- $$
dwDispPos		equ	_dwDispPos	- $$
dwMemSize		equ	_dwMemSize	- $$
dwMCRNumber		equ	_dwMCRNumber	- $$
ARDStruct		equ	_ARDStruct	- $$
	dwBaseAddrLow	equ	_dwBaseAddrLow	- $$
	dwBaseAddrHigh	equ	_dwBaseAddrHigh	- $$
	dwLengthLow	equ	_dwLengthLow	- $$
	dwLengthHigh	equ	_dwLengthHigh	- $$
	dwType		equ	_dwType		- $$
MemChkBuf		equ	_MemChkBuf	- $$
PageTableNumber		equ	_PageTableNumber- $$

DataLen			equ	$ - LABEL_DATA
; END of [SECTION .data1]


; 全局堆栈段
[SECTION .gs]
ALIGN	32
[BITS	32]
LABEL_STACK:
	times 512 db 0

TopOfStack	equ	$ - LABEL_STACK - 1

; END of [SECTION .gs]
; 堆栈段ring3
[SECTION .s3]
ALIGN	32
[BITS	32]
LABEL_STACK3:
	times 512 db 0
TopOfStack3	equ	$ - LABEL_STACK3 - 1
; END of [SECTION .s3]


; TSS ---------------------------------------------------------------------------------------------
[SECTION .tss]
ALIGN	32
[BITS	32]
LABEL_TSS:
		DD	0			; Back
		DD	TopOfStack		; 0 级堆栈
		DD	SelectorStack		; 
		DD	0			; 1 级堆栈
		DD	0			; 
		DD	0			; 2 级堆栈
		DD	0			; 
		DD	0			; CR3
		DD	0			; EIP
		DD	0			; EFLAGS
		DD	0			; EAX
		DD	0			; ECX
		DD	0			; EDX
		DD	0			; EBX
		DD	0			; ESP
		DD	0			; EBP
		DD	0			; ESI
		DD	0			; EDI
		DD	0			; ES
		DD	0			; CS
		DD	0			; SS
		DD	0			; DS
		DD	0			; FS
		DD	0			; GS
		DD	0			; LDT
		DW	0			; 调试陷阱标志
		DW	$ - LABEL_TSS + 2	; I/O位图基址
		DB	0ffh			; I/O位图结束标志
TSSLen		equ	$ - LABEL_TSS
; TSS ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	mov	[LABEL_GO_BACK_TO_REAL+3], ax
	mov	[_wSPValueInRealMode], sp

	; 得到内存数
	mov	ebx, 0
	mov	di, _MemChkBuf
.loop:
	mov	eax, 0E820h
	mov	ecx, 20
	mov	edx, 0534D4150h
	int	15h
	jc	LABEL_MEM_CHK_FAIL
	add	di, 20
	inc	dword [_dwMCRNumber]
	cmp	ebx, 0
	jne	.loop
	jmp	LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
	mov	dword [_dwMCRNumber], 0
LABEL_MEM_CHK_OK:

	; 初始化全局描述符
	InitDescBase LABEL_SEG_CODE16,LABEL_DESC_CODE16
	InitDescBase LABEL_SEG_CODE32,LABEL_DESC_CODE32
	InitDescBase LABEL_DATA, LABEL_DESC_DATA
	InitDescBase LABEL_STACK, LABEL_DESC_STACK
	InitDescBase LABEL_STACK3, LABEL_DESC_STACK3
	InitDescBase LABEL_TSS, LABEL_DESC_TSS

	InitDescBase LABEL_SEG_CODE_SWITCH, LABEL_DESC_CODE_SWITCH
	InitDescBase LABEL_SEG_CODE_EXIT, LABEL_DESC_CODE_EXIT

	; 初始化任务A的LDT
	InitDescBase LABEL_TASKA_LDT, LABEL_TASKA_DESC_LDT
	InitDescBase LABEL_TASKA_CODE, LABEL_TASKA_DESC_CODE

	; 初始化任务B的LDT
	InitDescBase LABEL_TASKB_LDT, LABEL_TASKB_DESC_LDT
	InitDescBase LABEL_TASKB_CODE, LABEL_TASKB_DESC_CODE

	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址

	; 加载 GDTR
	lgdt	[GdtPtr]

	; 关中断
	cli

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 准备切换到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 真正进入保护模式
	jmp	dword SelectorCode32:0	; 执行这一句会把 SelectorCode32 装入 cs, 并跳转到 Code32Selector:0  处

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LABEL_REAL_ENTRY:		; 从保护模式跳回到实模式就到了这里
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax

	mov	sp, [_wSPValueInRealMode]

	in	al, 92h		; ┓
	and	al, 11111101b	; ┣ 关闭 A20 地址线
	out	92h, al		; ┛

	sti			; 开中断

	mov	ax, 4c00h	; ┓
	int	21h		; ┛回到 DOS
; END of [SECTION .s16]


[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]

LABEL_SEG_CODE32:
	mov	ax, SelectorData
	mov	ds, ax			; 数据段选择子
	mov	es, ax
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子

	mov	ax, SelectorStack
	mov	ss, ax			; 堆栈段选择子

	mov	esp, TopOfStack

	; call ClearScreen

	; 下面显示一个字符串
	push	szPMMessage
	call	DispStr
	add	esp, 4

	push	szMemChkTitle
	call	DispStr
	add	esp, 4

	call	DispMemSize		; 显示内存信息
	; 根据内存大小计算应初始化多少PDE以及多少页表
	xor	edx, edx
	mov	eax, [dwMemSize]
	mov	ebx, 400000h	; 400000h = 4M = 4096 * 1024, 一个页表对应的内存大小
	div	ebx
	mov	ecx, eax	; 此时 ecx 为页表的个数，也即 PDE 应该的个数
	test	edx, edx
	jz	.no_remainder
	inc	ecx		; 如果余数不为 0 就需增加一个页表
.no_remainder:
	mov	[PageTableNumber], ecx	; 暂存页表个数

	
	; 初始化分页
	
	call	LABEL_INIT_PAGE_TABLE0
	call	LABEL_INIT_PAGE_TABLE1
	; 加载页目录
	mov	eax, PageDirBase0
	mov	cr3, eax

	; 启动分页
	mov	eax, cr0
	or	eax, 80000000h
	mov	cr0, eax
	jmp	short .3
.3:
	nop

	
	; Load TSS
	mov	ax, SelectorTSS
	ltr	ax	; 在任务内发生特权级变换时要切换堆栈，而内层堆栈的指针存放在当前任务的TSS中，所以要设置任务状态段寄存器 TR。

	; 加载 LDT
	mov	ax, SelectorLDTA
	lldt	ax

	push	SelectorStack3
	push	TopOfStack3
	push	SelectorTaskACode
	push	0
	retf		

;


; ClearScreen ------------------------------------------------------------------
ClearScreen:
	push	eax
	push	ebx
	push	ecx

	mov		ah, 00000000b			; 0000: 黑底    0000: 黑字
	mov		al, 0
	mov		ebx, 0
	mov		ecx, 4000
.1:
	mov		[gs:ebx], ax
	add		ebx, 2
	loop 	.1

	pop		ecx
	pop		ebx
	pop		eax

	ret
; END of ClearScreen -----------------------------------------------------------

InitPageTable 0
InitPageTable 1

; 显示内存信息 --------------------------------------------------------------
DispMemSize:
	push	esi
	push	edi
	push	ecx

	mov	esi, MemChkBuf
	mov	ecx, [dwMCRNumber]	;for(int i=0;i<[MCRNumber];i++) // 每次得到一个ARDS(Address Range Descriptor Structure)结构
.loop:					;{
	mov	edx, 5			;	for(int j=0;j<5;j++)	// 每次得到一个ARDS中的成员，共5个成员
	mov	edi, ARDStruct		;	{			// 依次显示：BaseAddrLow，BaseAddrHigh，LengthLow，LengthHigh，Type
.1:					;
	push	dword [esi]		;
	call	DispInt			;		DispInt(MemChkBuf[j*4]); // 显示一个成员
	pop	eax			;
	stosd				;		ARDStruct[j*4] = MemChkBuf[j*4];
	add	esi, 4			;
	dec	edx			;
	cmp	edx, 0			;
	jnz	.1			;	}
	call	DispReturn		;	printf("\n");
	cmp	dword [dwType], 1	;	if(Type == AddressRangeMemory) // AddressRangeMemory : 1, AddressRangeReserved : 2
	jne	.2			;	{
	mov	eax, [dwBaseAddrLow]	;
	add	eax, [dwLengthLow]	;
	cmp	eax, [dwMemSize]	;		if(BaseAddrLow + LengthLow > MemSize)
	jb	.2			;
	mov	[dwMemSize], eax	;			MemSize = BaseAddrLow + LengthLow;
.2:					;	}
	loop	.loop			;}
					;
	call	DispReturn		;printf("\n");
	push	szRAMSize		;
	call	DispStr			;printf("RAM size:");
	add	esp, 4			;
					;
	push	dword [dwMemSize]	;
	call	DispInt			;DispInt(MemSize);
	add	esp, 4			;

	pop	ecx
	pop	edi
	pop	esi
	ret
; ----------------------------------------------------------------------------

%include	"lib.inc"	; 库函数
SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]

[SECTION .sdest1]; 调用门目标段
[BITS	32]

LABEL_SEG_CODE_SWITCH:
	mov	eax, PageDirBase1
	mov	cr3, eax
	; Load LDT
	mov	ax, SelectorLDTB
	lldt	ax

	push	SelectorStack3
	push	TopOfStack3
	push	SelectorTaskBCode
	push	0
	retf

SegCodeSwitchLen	equ	$ - LABEL_SEG_CODE_SWITCH
; END of [SECTION .sdest]

[SECTION .sdest2]; 调用门目标段
[BITS	32]

LABEL_SEG_CODE_EXIT:
	jmp	SelectorCode16:0
SegCodeExitLen	equ	$ - LABEL_SEG_CODE_EXIT
; END of [SECTION .sdest]



; LDT
[SECTION .ldtA]
ALIGN	32
LABEL_TASKA_LDT:
;                                         段基址       段界限     ,   属性
LABEL_TASKA_DESC_CODE:	Descriptor	       0,     CodeALen - 1,   DA_C + DA_32 +DA_DPL3	; Code, 32 位

TASKALDTLen		equ	$ - LABEL_TASKA_LDT

; LDT 选择子
SelectorTaskACode	equ	LABEL_TASKA_DESC_CODE	- LABEL_TASKA_LDT + SA_TIL + SA_RPL3
; END of [SECTION .ldt]

[SECTION .taskA]
ALIGN	32
[BITS	32]
LABEL_TASKA_CODE:
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子(目的)

	mov	edi, (80 * 20 + 0) * 2	; 屏幕第 20 行, 第 0 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'T'
	mov	[gs:edi], ax

	mov edi, (80 * 20 + 1) * 2
	mov ah, 0Ch
	mov al, 'A'
	mov [gs:edi], ax

	mov edi, (80 * 20 + 2) * 2
	mov ah, 0Ch
	mov al, 'S'
	mov [gs:edi], ax

	
	mov edi, (80 * 20 + 3) * 2
	mov ah, 0Ch
	mov al, 'K'
	mov [gs:edi], ax

	
	mov edi, (80 * 20 + 4) * 2
	mov ah, 0Ch
	mov al, 'A'
	mov [gs:edi], ax

	call SelectorCallGateSwitch:0
	jmp $

CodeALen equ $ - LABEL_TASKA_CODE

; LDT
[SECTION .ldtB]
ALIGN	32
LABEL_TASKB_LDT:
;                                         段基址       段界限     ,   属性
LABEL_TASKB_DESC_CODE:	Descriptor	       0,     CodeBLen - 1,   DA_C + DA_32 +DA_DPL3	; Code, 32 位

TASKBLDTLen		equ	$ - LABEL_TASKB_LDT

; LDT 选择子
SelectorTaskBCode	equ	LABEL_TASKB_DESC_CODE	- LABEL_TASKB_LDT + SA_TIL + SA_RPL3
; END of [SECTION .ldt]

[SECTION .taskB]
ALIGN	32
[BITS	32]
LABEL_TASKB_CODE:
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子(目的)

	mov	edi, (80 * 21 + 0) * 2	; 屏幕第 20 行, 第 0 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'T'
	mov	[gs:edi], ax

	mov edi, (80 * 21 + 1) * 2
	mov ah, 0Ch
	mov al, 'A'
	mov [gs:edi], ax

	mov edi, (80 * 21 + 2) * 2
	mov ah, 0Ch
	mov al, 'S'
	mov [gs:edi], ax

	
	mov edi, (80 * 21 + 3) * 2
	mov ah, 0Ch
	mov al, 'K'
	mov [gs:edi], ax

	
	mov edi, (80 * 21 + 4) * 2
	mov ah, 0Ch
	mov al, 'B'
	mov [gs:edi], ax

	call SelectorCallGateExit:0
	jmp $

CodeBLen equ $ - LABEL_TASKB_CODE




; 16 位代码段. 由 32 位代码段跳入, 跳出后到实模式
[SECTION .s16code]
ALIGN	32
[BITS	16]
LABEL_SEG_CODE16:
	; 跳回实模式:
	mov	ax, SelectorNormal
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax

	mov	eax, cr0
	and     eax, 7FFFFFFEh          ; PE=0, PG=0
	mov	cr0, eax

LABEL_GO_BACK_TO_REAL:
	jmp	0:LABEL_REAL_ENTRY	; 段地址会在程序开始处被设置成正确的值

Code16Len	equ	$ - LABEL_SEG_CODE16

; END of [SECTION .s16code]

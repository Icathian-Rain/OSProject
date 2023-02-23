; 常量，宏定义内容

DA_32		EQU	4000h	; 32 位段
DA_LIMIT_4K	EQU	8000h	; 段界限粒度为 4K 字节

DA_DPL0		EQU	  00h	; DPL = 0
DA_DPL1		EQU	  20h	; DPL = 1
DA_DPL2		EQU	  40h	; DPL = 2
DA_DPL3		EQU	  60h	; DPL = 3
;----------------------------------------------------------------------------
; 存储段描述符类型值说明
;----------------------------------------------------------------------------
DA_DR		EQU	90h	; 存在的只读数据段类型值
DA_DRW		EQU	92h	; 存在的可读写数据段属性值
DA_DRWA		EQU	93h	; 存在的已访问可读写数据段类型值
DA_C		EQU	98h	; 存在的只执行代码段属性值
DA_CR		EQU	9Ah	; 存在的可执行可读代码段属性值
DA_CCO		EQU	9Ch	; 存在的只执行一致代码段属性值
DA_CCOR		EQU	9Eh	; 存在的可执行可读一致代码段属性值
;----------------------------------------------------------------------------
; 系统段描述符类型值说明
;----------------------------------------------------------------------------
DA_LDT		EQU	  82h	; 局部描述符表段类型值
DA_TaskGate	EQU	  85h	; 任务门类型值
DA_386TSS	EQU	  89h	; 可用 386 任务状态段类型值
DA_386CGate	EQU	  8Ch	; 386 调用门类型值
DA_386IGate	EQU	  8Eh	; 386 中断门类型值
DA_386TGate	EQU	  8Fh	; 386 陷阱门类型值
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; 选择子类型值说明
; 其中:
;       SA_  : Selector Attribute

SA_RPL0		EQU	0	; ┓
SA_RPL1		EQU	1	; ┣ RPL
SA_RPL2		EQU	2	; ┃
SA_RPL3		EQU	3	; ┛

SA_TIG		EQU	0	; ┓TI
SA_TIL		EQU	4	; ┛
;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
; 分页机制使用的常量说明
;----------------------------------------------------------------------------
PG_P		EQU	1	; 页存在属性位
PG_RWR		EQU	0	; R/W 属性位值, 读/执行
PG_RWW		EQU	2	; R/W 属性位值, 读/写/执行
PG_USS		EQU	0	; U/S 属性位值, 系统级
PG_USU		EQU	4	; U/S 属性位值, 用户级
;----------------------------------------------------------------------------


; 宏 ------------------------------------------------------------------------------------------------------
;
; 描述符
; usage: Descriptor Base, Limit, Attr
;        Base:  dd
;        Limit: dd (low 20 bits available)
;        Attr:  dw (lower 4 bits of higher byte are always 0)
%macro Descriptor 3
	dw	%2 & 0FFFFh				; 段界限 1				(2 字节)
	dw	%1 & 0FFFFh				; 段基址 1				(2 字节)
	db	(%1 >> 16) & 0FFh			; 段基址 2				(1 字节)
	dw	((%2 >> 8) & 0F00h) | (%3 & 0F0FFh)	; 属性 1 + 段界限 2 + 属性 2		(2 字节)
	db	(%1 >> 24) & 0FFh			; 段基址 3				(1 字节)
%endmacro ; 共 8 字节
;
; 门
; usage: Gate Selector, Offset, DCount, Attr
;        Selector:  dw
;        Offset:    dd
;        DCount:    db
;        Attr:      db
%macro Gate 4
	dw	(%2 & 0FFFFh)				; 偏移 1				(2 字节)
	dw	%1					; 选择子				(2 字节)
	dw	(%3 & 1Fh) | ((%4 << 8) & 0FF00h)	; 属性					(2 字节)
	dw	((%2 >> 16) & 0FFFFh)			; 偏移 2				(2 字节)
%endmacro ; 共 8 字节
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


; 初始化段描述符
; usage: InitDescBase LABEL, LABEL_DESC
%macro InitDescBase 2
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, %1
	mov	word [%2 + 2], ax
	shr	eax, 16
	mov	byte [%2 + 4], al
	mov	byte [%2 + 7], ah
%endmacro

; 初始化任务描述符
; usage: InitTaskDescBase num
%macro InitTaskDescBase 1
	InitDescBase LABEL_TASK%1_LDT, LABEL_TASK%1_DESC_LDT
	InitDescBase LABEL_TASK%1_CODE, LABEL_TASK%1_DESC_CODE
	InitDescBase LABEL_TASK%1_DATA, LABEL_TASK%1_DESC_DATA 
	InitDescBase LABEL_TASK%1_STACK0, LABEL_TASK%1_DESC_STACK0 
	InitDescBase LABEL_TASK%1_STACK3, LABEL_TASK%1_DESC_STACK3 
%endmacro



; 定义LDT
; usage: DefineLDT num
%macro DefineLDT 1
[SECTION .ldt%1]
ALIGN	32
LABEL_TASK%1_LDT:
;                                         段基址       段界限     ,   属性
LABEL_TASK%1_DESC_DATA: Descriptor	0,	Task%1DataLen - 1,	 DA_DRWA + DA_DPL3
LABEL_TASK%1_DESC_CODE: Descriptor	0,	Task%1CodeLen - 1,	 DA_C + DA_32 + DA_DPL3
LABEL_TASK%1_DESC_STACK0: Descriptor	0,	TopOfTask%1Stack0,	 DA_DRWA + DA_32
LABEL_TASK%1_DESC_STACK3: Descriptor	0,	TopOfTask%1Stack3,	 DA_DRWA + DA_32 + DA_DPL3


TASK%1LDTLen		equ	$ - LABEL_TASK%1_LDT=
; LDT 选择子
SelectorTask%1Data	equ	LABEL_TASK%1_DESC_DATA - LABEL_TASK%1_LDT + SA_TIL + SA_RPL3
SelectorTask%1Code	equ	LABEL_TASK%1_DESC_CODE - LABEL_TASK%1_LDT + SA_TIL + SA_RPL3
SelectorTask%1Stack0	equ	LABEL_TASK%1_DESC_STACK0 - LABEL_TASK%1_LDT + SA_TIL
SelectorTask%1Stack3	equ	LABEL_TASK%1_DESC_STACK3 - LABEL_TASK%1_LDT + SA_TIL + SA_RPL3
; END of [SECTION .ldt]
%endmacro


;定义任务数据段
; usage: DefineTaskData num, string
%macro DefineTaskData 2
[SECTION .task%1data]
ALIGN	32
[BITS	32]
LABEL_TASK%1_DATA:
	; 任务数据段
	_szTask%1Message: db %2, 0
	szTask%1Message	equ	_szTask%1Message - $$
Task%1DataLen	equ	$ - LABEL_TASK%1_DATA
; END of [SECTION .task%1data]
%endmacro

; 定义任务代码段
; usage: DefineTaskCode num, color
%macro DefineTaskCode 2
[SECTION .task%1code]
ALIGN	32
[BITS	32]
LABEL_TASK%1_CODE:
; 遍历输出szTask0Message
	xor 	ecx, ecx
	mov 	ah, %2
.outputLoop:
	mov 	al, [szTask%1Message + ecx]
	mov 	[gs:((80 * 20 + ecx) * 2)], ax
	inc 	ecx
	; 判断是否到达字符串末尾
	cmp 	al, 0
	jne 	.outputLoop
	jmp		LABEL_TASK%1_CODE

Task%1CodeLen	equ	$ - LABEL_TASK%1_CODE
; END of [SECTION .task%1code]
%endmacro

; 定义任务堆栈0
; usage: DefineTaskStack0 num
%macro DefineTaskStack0 1
[SECTION .task%1stack0]
ALIGN	32
[BITS	32]
LABEL_TASK%1_STACK0:
	times 512 db 0
TopOfTask%1Stack0	equ	$ - LABEL_TASK%1_STACK0 - 1
; END of [SECTION .task%1stack0]
%endmacro

; 定义任务堆栈3
; usage: DefineTaskStack3 num
%macro DefineTaskStack3 1
[SECTION .task%1stack3]
ALIGN	32
[BITS	32]
LABEL_TASK%1_STACK3:
	times 512 db 0
TopOfTask%1Stack3	equ	$ - LABEL_TASK%1_STACK3 - 1
; END of [SECTION .task%1stack3]
%endmacro

; 定义任务
; usage: DefineTask num, string, color
%macro DefineTask 3
	DefineLDT	%1
	DefineTaskCode	%1, %3
	DefineTaskData	%1, %2
	DefineTaskStack0	%1
	DefineTaskStack3	%1
%endmacro

; 定义初始化页表
; usage: DefineInitPageTable num
%macro InitPageTable 1
LABEL_INIT_PAGE_TABLE%1:
		; 初始化页目录
	mov		ax, SelectorFlatRW
	mov		es, ax
	mov		edi, PageDirBase%1		; 此段首地址为 PageDirBase1
	xor		eax, eax
	mov		eax, PageTblBase%1 | PG_P  | PG_USU | PG_RWW
	mov		ecx, [PageTableNumber]
.1:
	stosd
	add		eax, 4096				; 为了简化, 所有页表在内存中是连续的.
	loop	.1

	; 再初始化所有页表
	mov		eax, [PageTableNumber]	; 页表个数
	mov		ebx, 1024				; 每个页表 1024 个 PTE
	mul		ebx
	mov		ecx, eax				; PTE个数 = 页表个数 * 1024
	mov		edi, PageTblBase%1		; 此段首地址为 PageTblBase1
	xor		eax, eax
	mov		eax, PG_P  | PG_USU | PG_RWW
.2:
	stosd
	add		eax, 4096				; 每一页指向 4K 的空间
	loop	.2

	ret
; End of SetupPaging1 ----------------------------------------------------------
%endmacro


; 切换到任务
; usage: SwitchTask num
%macro SwitchTask 1

	mov		ax, SelectorLDT%1	; ┳ 加载 LDT
	lldt	ax					; ┛
	
	mov		eax, PageDirBase%1	; ┳ 加载 CR3
	mov		cr3, eax			; ┛

	; 修改ds为任务0的数据段
	mov		eax, SelectorTask%1Data
	mov		ds, eax

	; 使用 iretd 进行任务切换, 切换至任务 0
	push	SelectorTask%1Stack3	; SS
	push	TopOfTask%1Stack3	; ESP
	pushfd						; EFLAGS
	pop		eax					; ┓
	or		eax, 0x200			; ┣ 将 EFLAGS 中的 IF 位置 1, 即开启中断
	push	eax					; ┛
	push	SelectorTask%1Code	; CS
	push	0					; EIP
	iretd
	iretd
%endmacro
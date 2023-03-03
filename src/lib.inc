; Init8259A --------------------------------------------------------------------
Init8259A:
	mov		al, 011h
	out		020h, al	; 主8259, ICW1.
	call	io_delay

	out		0A0h, al	; 从8259, ICW1.
	call	io_delay

	mov		al, 020h	; IRQ0 对应中断向量 0x20
	out		021h, al	; 主8259, ICW2.
	call	io_delay

	mov		al, 028h	; IRQ8 对应中断向量 0x28
	out		0A1h, al	; 从8259, ICW2.
	call	io_delay

	mov		al, 004h	; IR2 对应从8259
	out		021h, al	; 主8259, ICW3.
	call	io_delay

	mov		al, 002h	; 对应主8259的 IR2
	out		0A1h, al	; 从8259, ICW3.
	call	io_delay

	mov		al, 001h
	out		021h, al	; 主8259, ICW4.
	call	io_delay

	out		0A1h, al	; 从8259, ICW4.
	call	io_delay

	mov		al, 11111110b	; 仅仅开启定时器中断
	; mov		al, 11111111b	; 屏蔽主8259所有中断
	out		021h, al	; 主8259, OCW1.
	call	io_delay

	mov		al, 11111111b	; 屏蔽从8259所有中断
	out		0A1h, al	; 从8259, OCW1.
	call	io_delay

	ret
; END of Init8259A -------------------------------------------------------------

; SetRealmode8259A -------------------------------------------------------------
SetRealmode8259A:
	mov		ax, SelectorData
	mov		fs, ax

	mov		al, 017h
	out		020h, al	; 主8259, ICW1.
	call	io_delay

	mov		al, 008h	; IRQ0 对应中断向量 0x8
	out		021h, al	; 主8259, ICW2.
	call	io_delay

	mov		al, 001h
	out		021h, al	; 主8259, ICW4.
	call	io_delay

	mov		al, [fs:SavedIMREG]	; ┓恢复中断屏蔽寄存器 IMREG 的原值
	out		021h, al			; ┛
	call	io_delay

	ret
; END of SetRealmode8259A ------------------------------------------------------

; Init8253A --------------------------------------------------------------------
Init8253A:
	mov		al, 00110110b		; 通道 0 的 CONTROL 字节
	out		043h, al			; 设置 8253A 芯片, 2 字节计数值, 模式 3, 二进制计数
	call	io_delay

	mov		ax, 59659			; 频率 20 Hz, 时钟周期为50ms, 设置 COUNT 为 1193180 / 20 = 59659
	out		040h, al			; 将 COUNT 的低位写入通道 0
	call	io_delay

	mov		al, ah
	out		040h, al			; 将 COUNT 的高位写入通道 0
	call	io_delay

	ret
; END of Init8253A -------------------------------------------------------------

; io_delay ---------------------------------------------------------------------
io_delay:
	nop
	nop
	nop
	nop
	ret
; END of io_delay --------------------------------------------------------------

; ------------------------------------------------------------------------
; 显示 AL 中的数字
; ------------------------------------------------------------------------
DispAL:
	push	ecx
	push	edx
	push	edi

	mov	edi, [dwDispPos]

	mov	ah, 0Fh			; 0000b: 黑底    1111b: 白字
	mov	dl, al
	shr	al, 4
	mov	ecx, 2
.begin:
	and	al, 01111b
	cmp	al, 9
	ja	.1
	add	al, '0'
	jmp	.2
.1:
	sub	al, 0Ah
	add	al, 'A'
.2:
	mov	[gs:edi], ax
	add	edi, 2

	mov	al, dl
	loop	.begin
	;add	edi, 2

	mov	[dwDispPos], edi

	pop	edi
	pop	edx
	pop	ecx

	ret
; DispAL 结束-------------------------------------------------------------


; ------------------------------------------------------------------------
; 显示一个整形数
; ------------------------------------------------------------------------
DispInt:
	mov	eax, [esp + 4]
	shr	eax, 24
	call	DispAL

	mov	eax, [esp + 4]
	shr	eax, 16
	call	DispAL

	mov	eax, [esp + 4]
	shr	eax, 8
	call	DispAL

	mov	eax, [esp + 4]
	call	DispAL

	mov	ah, 07h			; 0000b: 黑底    0111b: 灰字
	mov	al, 'h'
	push	edi
	mov	edi, [dwDispPos]
	mov	[gs:edi], ax
	add	edi, 4
	mov	[dwDispPos], edi
	pop	edi

	ret
; DispInt 结束------------------------------------------------------------

; ------------------------------------------------------------------------
; 显示一个字符串
; ------------------------------------------------------------------------
DispStr:
	push	ebp
	mov	ebp, esp
	push	ebx
	push	esi
	push	edi

	mov	esi, [ebp + 8]	; pszInfo
	mov	edi, [dwDispPos]
	mov	ah, 0Fh
.1:
	lodsb
	test	al, al
	jz	.2
	cmp	al, 0Ah	; 是回车吗?
	jnz	.3
	push	eax
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	eax
	jmp	.1
.3:
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1

.2:
	mov	[dwDispPos], edi

	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
; DispStr 结束------------------------------------------------------------

; ------------------------------------------------------------------------
; 换行
; ------------------------------------------------------------------------
DispReturn:
	push	szReturn
	call	DispStr			;printf("\n");
	add	esp, 4

	ret
; DispReturn 结束---------------------------------------------------------


; ------------------------------------------------------------------------
; 内存拷贝，仿 memcpy
; ------------------------------------------------------------------------
; void* MemCpy(void* es:pDest, void* ds:pSrc, int iSize);
; ------------------------------------------------------------------------
MemCpy:
	push	ebp
	mov	ebp, esp

	push	esi
	push	edi
	push	ecx

	mov	edi, [ebp + 8]	; Destination
	mov	esi, [ebp + 12]	; Source
	mov	ecx, [ebp + 16]	; Counter
.1:
	cmp	ecx, 0		; 判断计数器
	jz	.2		; 计数器为零时跳出

	mov	al, [ds:esi]		; ┓
	inc	esi			; ┃
					; ┣ 逐字节移动
	mov	byte [es:edi], al	; ┃
	inc	edi			; ┛

	dec	ecx		; 计数器减一
	jmp	.1		; 循环
.2:
	mov	eax, [ebp + 8]	; 返回值

	pop	ecx
	pop	edi
	pop	esi
	mov	esp, ebp
	pop	ebp

	ret			; 函数结束，返回
; MemCpy 结束-------------------------------------------------------------

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

; DispMemSize ------------------------------------------------------------------
DispMemSize:
	push	esi
	push	edi
	push	ecx

	mov		esi, MemChkBuf
	mov		ecx, [dwMCRNumber]		;for(int i = 0; i < [MCRNumber]; i++) // 每次得到一个ARDS(Address Range Descriptor Structure)结构
.loop:								;{
	mov		edx, 5					;	for(int j = 0; j < 5; j++)	// 每次得到一个ARDS中的成员，共5个成员
	mov		edi, ARDStruct			;	{
.1:									;		// 依次显示：BaseAddrLow，BaseAddrHigh，LengthLow，LengthHigh，Type
	push	dword [esi]				;
	call	DispInt					;		DispInt(MemChkBuf[j * 4]); // 显示一个成员
	pop		eax						;
	stosd							;		ARDStruct[j * 4] = MemChkBuf[j * 4];
	add		esi, 4					;
	dec		edx						;
	cmp		edx, 0					;
	jnz		.1						;	}
	call	DispReturn				;	printf("\n");
	cmp		dword [dwType], 1		;	if(Type == AddressRangeMemory) // AddressRangeMemory : 1, AddressRangeReserved : 2
	jne		.2						;	{
	mov		eax, [dwBaseAddrLow]	;
	add		eax, [dwLengthLow]		;
	cmp		eax, [dwMemSize]		;		if(BaseAddrLow + LengthLow > MemSize)
	jb		.2						;
	mov		[dwMemSize], eax		;			MemSize = BaseAddrLow + LengthLow;
.2:									;	}
	loop	.loop					;}
									;
	call	DispReturn				;printf("\n");
	push	szRAMSize				;
	call	DispStr					;printf("RAM size:");
	add		esp, 4					;
									;
	push	dword [dwMemSize]		;
	call	DispInt					;DispInt(MemSize);
	add		esp, 4					;

	pop		ecx
	pop		edi
	pop		esi
	ret
; End of DispMemSize -----------------------------------------------------------
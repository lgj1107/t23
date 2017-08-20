
	
	jmp	sk
.if 1
	mov	edi,0x600
	lea	rsi,[rip+user_task]
	cld
	mov	ecx,512
	rep	movsb
	
	mov	word ptr [0x472],0x1234
	mov	word ptr [0x467],0x600
	mov	word ptr [0x467+2],0
	
	mov	al,0xf
	out	0x70,al
	mov	al,0xa
	out	0x71,al

	mov	esi,APIC_ICR_LO
	mov	edi,APIC_ICR_HI
	mov	eax,2 << 24
	mov	[rdi],eax
	mov	eax,APIC_DEST_DESTFLD|APIC_LEVEL_ASSERT|APIC_DESTMODE_PHY|APIC_DELMODE_INIT
	mov	[rsi],eax

	mov	ecx,256
1:	
	in	al,0x84
	loop	1b

	mov	eax,APIC_DEST_DESTFLD|APIC_LEVEL_DEASSERT|APIC_DESTMODE_PHY|APIC_DELMODE_INIT
	mov	[rsi],eax
	
	mov	eax,[rsi]
	mov	edi,0xb8000+160*5
	call	hex64
.endif

sk:
	mov	edi,0xb8000+160*8
	xor	eax,eax
	movabs	al,[ap_cpu]
	call	hex64
	add	edi,2
	mov	al,[rip+ap_cpu]
	call	hex64


	.include "../include/apicreg.def"
	.include "../include/regs.def"
	.include "../include/misc.def"
	.include "../include/mem.inc"
	.global	keyb
	.intel_syntax noprefix
keyb:	push	rax
	push_fram
	in	al,0x60
	cmp	al,0x38
	je	alt_key
	cmp	al,0x3b
	je	alt_f1_key
	cmp	al,0xb8
	je	unalt
	cmp	al,0x3c
	je	alt_f2_key
keyb1:
keyb9:
	pop_fram
	xor	eax,eax
	mov	[APIC_EOI],eax
	pop	rax
	iretq
unalt:
#	mov	al,[rip+key_csa]
	and	byte ptr [rip+key_csa],0xfe
#	btr	eax,0
#	mov	[rip+key_csa],al
	jmp	keyb9
key_count:
	.byte	0x0
alt_key:
	mov	al,[rip+key_csa]
	bts	eax,0
	mov	[rip+key_csa],al
	jmp	keyb9
alt_f1_key:
	test	byte ptr [rip+key_csa],1
	jz	keyb9
	test	byte ptr [rip+screen],1
	jz	fis.0
	mov	esi,0xb8000
	lea	edi,[rip+cpu1_disp]
	mov	ecx,(80*25*2)/8
	cld
	rep	movsq
	mov	edi,0xb8000
	lea	esi,[rip+cpu0_disp]
	mov	ecx,(80*25*2)/8
	rep	movsq
	
	jmp	keyb9
fis.0:
	mov	esi,0xb8000
	lea	edi,[rip+cpu0_disp]
	mov	ecx,(80*25*2)/8
	cld
	rep	movsq
	
	jmp	keyb9
alt_f2_key:
	test	byte ptr [rip+key_csa],1
	jz	keyb9
	test	byte ptr [rip+screen],1
	jnz	is.1
is.0:
	mov	byte ptr [rip+screen],1
	mov	esi,0xb8000
	lea	rdi,[rip+cpu0_disp]
	mov	ecx,(80*25*2)/8
	cld
	rep	movsq
	mov	edi,0xb8000
	xor	eax,eax
	mov	ecx,(80*25*2)/8
	rep	stosq
	jmp	keyb9
is.1:
	mov	esi,0xb8000
	lea	rdi,[rip+cpu0_disp]
	mov	ecx,(80*25*2)/8
	cld
	rep	movsq

	mov	edi,0xb8000
	lea	rsi,[rip+cpu1_disp]
	mov	ecx,(80*25*2)/8
	cld
	rep	movsq

	jmp	keyb9

ctrl_key:
	mov	al,[rip+key_csa]
	bts	eax,2
	mov	[rip+key_csa],al
	jmp	keyb9
ctrl_f1_key:
	test	byte ptr [rip+key_csa],0x4
	jz	keyb9
	mov	al,[rip+key_csa]
	mov	edi,0xb8000+160*2+128
	call	hex64
	xor	byte ptr [rip+key_csa],0x4
	test	byte ptr [rip+screen],1
	jz	c.1
	mov	esi,0xb8000
	lea	rdi,[rip+cpu0_disp]
	cld
	mov	ecx,(80*25*2)/8
	rep	movsq
	mov	edi,0xb8000
	lea	rsi,[rip+cpu0_disp]
	mov	ecx,(80*25*2)/8
	rep	movsq
	
c.1:
	jmp	keyb9
ctrl_f2_key:
	test	byte ptr [rip+key_csa],0x4
	jz	keyb9
	xor	byte ptr [rip+key_csa],0x4
	mov	al,[rip+key_csa]
	mov	edi,0xb8000+160*16+128
	call	hex64
	test	byte ptr [rip+screen],1
	jz	cf2.9
cf2.1:
	cld
	mov	esi,0xb8000
	lea	rdi,[rip+cpu0_disp]
	mov	ecx,(80*25*2)/8
	rep	movsq

	lea	rsi,[rip+cpu1_disp]
	mov	edi,0xb8000
	mov	ecx,(80*25*2)/8
	rep	movsq

cf2.8:	
	jmp	keyb9
cf2.9:
	mov	byte ptr [rip+screen],1
		
	lea	rdi,[rip+cpu0_disp]
	mov	esi,0xb8000
	cld
	mov	ecx,(80*25*2)/8
	rep	movsq

	mov	edi,0xb8000
	mov	ecx,(80*25*2)/8
	xor	eax,eax
	rep	stosq
	jmp	cf2.8


#
#alt = 0x01
#shift = 0x2
#ctrl = 0x4
key_csa:
	.byte	0x0
screen:
	.byte	0x0

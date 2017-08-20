	.set	mp_trampoline,0x9f000

	.include "regs.def"
	.include "misc.def"
	.include "apicreg.def"
	.include "mem.inc"
	.set	highmemory,0x80000000

	.code16
	
	.global	start
	.intel_syntax noprefix
start:
	cli
	xor	ax,ax
	mov	es,ax
	mov	ds,ax

.if 1
	mov	al,-1
	out	0x21,al
	jmp	$+2
	out	0xa1,al
.endif	
	in	al,0x92
	or	al,2
	out	0x92,al
	
	lgdt	gdtr
	mov	eax,cr0
	or	al,1
	mov	cr0,eax
	ljmp	0x8,offset start32
	.code32
start32:
	mov	eax,0x10
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	mov	esp,0x1000


	mov	esi,0x90004 
	xor	ebx,ebx
	mov	bl,[esi-4]
	mov	ecx,20
	imul	ebx,ecx
	add	esi,ebx
s.0:
	mov	eax,[esi+int15_type]
	cmp	eax,1
	je	map_is_1
	sub	esi,20
	jmp	s.0
map_is_1:
	mov	eax,[esi+lengthhigh]
	test	eax,eax
	jnz	gte4g
	mov	dword ptr [kernel_phy],512*1024*1024
	jmp	map.1
gte4g:
	mov	dword ptr [kernel_phy],highmemory
map.1:
	mov	eax,[kernel_phy]
	mov	[boot1_end+24],eax
	mov	[page_base],eax			#AP CPU page table
s.1:
	mov	edi,mp_trampoline
	mov	esi,offset bootmp
	mov	ecx,bootmp_end - bootmp
	rep	movsb

	mov	edi,[kernel_phy]
	mov	ebx,edi				#save kernel physical address
	xor	eax,eax
	mov	ecx,(64*1024*1024)/4
	rep	stosd
	
	lea	edi,[ebx+kernel_base_begin]
	mov	esi,offset boot1_end
	mov	ecx,[esi+4]
	mov	edx,ecx
	and	ecx,~3
	rep	movsb
	mov	ecx,edx
	shr	ecx,2
	rep	movsd

	mov	edi,ebx			#PML4E address
	mov	eax,PAGE_PDPTE|PG_P|PG_RW|PG_US
	add	eax,ebx
	mov	edx,((reloc >> 39) & 0x1ff) << 3
#	mov	edx,((reloc shr 39) and 0x1ff) shl 3
	mov	[edi+edx],eax
	mov	[edi],eax

	lea	edi,[ebx+PAGE_PDPTE]
	mov	eax,PAGE_KNL_PDE|PG_P|PG_RW|PG_US
	add	eax,ebx
	mov	edx,((reloc >> 30) & 0x1ff) << 3
	mov	[edi+edx],eax				#核的PDE

	mov	eax,PAGE_TEMP_PDE|PG_P|PG_RW|PG_US
	add	eax,ebx
	mov	[edi],eax

	mov	eax,PAGE_APIC_PDE|PG_P|PG_RW
	add	eax,ebx
	mov	edx,((IO_APIC_BASE >> 30) & 0x1ff) << 3
	mov	[edi+edx],eax	

	lea	edi,[ebx+PAGE_KNL_PDE]
	mov	eax,ebx
	or	eax,PG_P|PG_RW|PG_PS|PG_US	#
	mov	ecx,32
	mov	edx,PG_2M
p.1:
	mov	[edi],eax
	lea	edi,[edi+8]
	add	eax,edx
	loop	p.1

	mov	esi,edi
	lea	edi,[ebx+PAGE_TEMP_PDE]
	mov	eax,PG_P|PG_RW|PG_PS|PG_US
	mov	ecx,32
p.2:
	mov	[edi],eax
	lea	edi,[edi+8]
	add	eax,edx
	loop	p.2

	lea	edi,[ebx+PAGE_TEMP_PDE]
	mov	ecx,(((vmx_begin&0x3fe00000)>>21)<<3)
	mov	eax,0x1a000000|PG_P|PG_RW|PG_PS
	lea	edi,[edi+ecx]
	mov	ecx,16
p.3:
	mov	[edi],eax
	lea	edi,[edi+8]
	add	eax,edx
	loop	p.3
.if 0
	mov	edi,PAGE_TEMP_PDE
	mov	eax,0x3fe00000|PG_P|PG_RW|PG_PS		#VESA LFB (debian 2.0)
	mov	[edi+0xff8],eax
.endif
	mov	edi,PAGE_APIC_PDE +(((IO_APIC_BASE &0x3fe00000)>>21)<<3)
	add	edi,ebx
	mov	eax,IO_APIC_BASE|PG_P|PG_RW|PG_PS|PG_US
	mov	ecx,2
p.4:
	mov	[edi],eax
	lea	edi,[edi+8]
	add	eax,edx
	loop	p.4

	mov	eax,cr4
	or	eax,CR4_FXSR|CR4_PAE
#	or	eax,CR4_FXSR|CR4_PAE|CR4_VMXE		#AMD CR4 no vmxe bit
	mov	cr4,eax
	
	mov	ecx,MSR_EFER
	rdmsr
	or	eax,EFER_SCE|EFER_LME
	wrmsr
	
	mov	ebx,[kernel_phy]
	mov	cr3,ebx

	mov	eax,cr0
	and	eax,~0x60000000
	or	eax,0x80000020
	mov	cr0,eax
	jmp	0x28:start64
	
	.code32
.if 1
hex32:
	push	eax
	shr	eax,16
	call	hex_16
	pop	eax
hex_16:
	push	eax
	shr	ax,8
	call	hex_8
	pop	eax
hex_8:
	push	eax
	shr	al,4
	call	hex8_1
	pop	eax
hex8_1:
	and	al,0xf
	add	al,0x30
	cmp	al,0x39
	jbe	hex8_2
	add	al,0x7
hex8_2:
	mov	ah,2
	stosw		
	ret
.endif
	.code64
start64:
	xor	eax,eax
	mov	ds,ax
	mov	es,ax
	mov	fs,ax
	mov	gs,ax
	mov	ss,ax
	mov	rsp,0x90000
	push	2
	popfq
	mov	rax,reloc + (2*16*1024 *1024)  + 32
	jmp	rax

	.code64
	.if 0
	.global	hex64,hex32
hex64:
	push	rax
	shr	rax,32
	call	hex32
	pop	rax
hex32:
	push	rax
	shr	rax,16
	call	hex_16
	pop	rax
hex_16:
	push	rax
	shr	ax,8
	call	hex_8
	pop	rax
hex_8:
	push	rax
	shr	al,4
	call	hex8_1
	pop	rax
hex8_1:
	and	al,0xf
	add	al,0x30
	cmp	al,0x39
	jbe	hex8_2
	add	al,0x7
hex8_2:
	mov	ah,2
	stosw		
	ret
	.endif
	.code16
bootmp:
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	mov	sp,0xa00
	cli
	mov	eax,gdt - bootmp + mp_trampoline
	mov	di,gdtr - bootmp
	mov	[di+2],eax
	lgdt	[di]
h.1:	
	mov	eax,cr4
	or	eax,CR4_FXSR|CR4_PAE
	mov	cr4,eax

	mov	ecx,MSR_EFER
	rdmsr
	or	eax,EFER_SCE|EFER_LME
	wrmsr
	mov	eax,[page_base - bootmp]
	mov	cr3,eax

	mov	eax,cr0
	or	eax,0x80000021
	mov	cr0,eax
	.byte	0x66
	.byte	0xea
	.long	ap64-bootmp + mp_trampoline
	.word	0x28
	.code64
ap64:
	xor	eax,eax
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	mov	rsp,mp_trampoline
	push	2
	popfq

	mov	rax,[boot1_end + 8]
	jmp	rax
	jmp	$
page_base:.quad	0x0
gdtr:
	.word	7*8
	.long	offset gdt
	.long	0x0
gdt:
	.quad	0x0
	.quad	0x00cf9a000000ffff
	.quad	0x00cf92000000ffff
	.quad	0x00009a000000ffff
	.quad	0x000092000000ffff
	.quad	0x00209a0000000000
	.quad	0x0000920000000000
bootmp_end:
kernel_phy:	.long	0x0
		.long	0x0	
int15_map:
	.quad	0x0
data_end:
	
	.org 2048
boot1_end:

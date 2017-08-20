	.include "../include/vmcs.def"
	.include "../include/apicreg.def"
	.include "../include/regs.def"
	.include "../include/misc.def"
	.include "../include/mem.inc"
	.global	vm_exit
	.intel_syntax noprefix
	.code64
vm_exit:
	pushfq
#	push	rcx
#	push	rbx
#	push	rdx
	push	rdi
	push	rsi
	push	rbp
	push	rax

	mov	ebx,VMCS_EXIT_REASON
	vmread	rax,rbx
	cmp	eax,0xa			#CPUID
	je	cpuid.0a
#	cmp	eax,0xc			#HLT
#	je	reason_0xc
#	cmp	eax,0x30
#	cmp	eax,0x20		#WRMSR
#	je	wrmsr_err
	cmp	al,EXIT_REASON_EXT_INTR
	je	reason_0x1		#external_interrupt
	jmp	v.0
cpuid.0a:
	mov	rbx,VMCS_VMEXIT_INSTRUCTION_LEN
	vmread	r8,rbx
	mov	rbx,VMCS_GUEST_RIP
	vmread	rax,rbx
	add	r8,rax
	vmwrite	rbx,r8
	pop	rax
	cmp	eax,4
	jbe	cpuid.4
	xor	eax,eax
	mov	ebx,eax
	mov	ecx,eax
	mov	edx,eax
	jmp	cpuid.5
cpuid.4:
	cpuid
#	xor	eax,eax
cpuid.5:
	push	rax
resume:
	pop	rax
	pop	rbp
	pop	rsi
	pop	rdi
#	pop	rdx
#	pop	rbx
#	pop	rcx
	popfq
resume.0:
	vmresume
reason_0x1:
	
	mov	ebx,VMCS_VMEXIT_INTERRUPTION_INFO
	vmread	rax,rbx
	cmp	al,0x77
	ja	r01.9
	cmp	al,0x70
	ja	r01.9
r01.8:
	cmp	al,0xf
	ja	r01.9
	cmp	al,0x8
	jb	r01.9
	jmp	$
r01.9:
	
	mov	edi,eax
	mov	ebx,VMCS_HOST_IDTR_BASE	
	vmread	rdx,rbx
	mov	edi,0xb8000+160*9+64
	call	hex64
	jmp	$
	jmp	resume
reason_0xd:
	mov	rbx,VMCS_GUEST_RIP
	vmread	rax,rbx
	add	eax,2		#INVD 0xf,0x8
	vmwrite	rbx,rax
	jmp	resume
reason_0xc:
	mov	rbx,VMCS_GUEST_RIP
	vmread	rax,rbx
	inc	rax
	vmwrite	rbx,rax

#	mov	r8,VMCS_VMENTRY_INSTRUCTION_LEN
#	vmread	rcx,r8

	mov	r8,VMCS_GUEST_SS_SEL
	vmread	rax,r8
	mov	rax,[rsp+64]
	mov	edi,0xb8000+160*8
	call	hex64
	pop	rax
	pop	rbp
	pop	rsi
	pop	rdi
	pop	rdx
	pop	rbx
	pop	rcx
	popfq
	stc

	jmp	resume
wrmsr_err:
	mov	rbx,VMCS_GUEST_RIP
	vmread	rax,rbx
	mov	edi,0xb8000+160*8 + 64
	mov	eax,ecx
	call	hex64
	jmp	$
reason_table:
	.long	0x0

#
#1 = word
#2 = long
#4 = quad
#8 = end of line
#0x80 = 控制符
#
	.set	B16,1
	.set	B32,2
	.set	B64,4
	.set	EOL,8
v.0:
	mov	ebx,VMCS_VMEXIT_INSTRUCTION_LEN
	vmread	rax,rbx
	mov	rbx,VMCS_GUEST_RIP
	vmread	rax,rbx
	
	mov	ecx,0x482
	rdmsr
	mov	edi,0xb8000+160*5
#	mov	rax,[rax]
	call	hex64
v.2:
	call	dump_vmcs
	jmp	$
dump_vmcs:
#	mov	ebx,VMCS_VMEXIT_INTERRUPTION_INFO
#	vmread	rax,rbx
#	push	rax
	mov	ebx,VMCS_GUEST_RFLAGS
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_GUEST_CR0
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_GUEST_CR4
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_VM_INSTRUCTION_ERR
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_IDT_VECTORING_INFO_FIELD	#,0x4408
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_IDT_VECTORING_ERRCODE	
	vmread	rax,rbx
	push	rax

	mov	ebx,VMCS_VMEXIT_INTERRUPTION_ERRCODE
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_VMEXIT_INTERRUPTION_INFO
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_VMEXIT_INSTRUCTION_LEN
	vmread	rax,rbx
	push	rax
	mov	rbx,VMCS_GUEST_RIP
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_GUEST_CR3
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_GUEST_LINEAR_ADDR
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_GUEST_PHYSICAL_ADDR
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_EXIT_QUALIFICATION
	vmread	rax,rbx
	push	rax
	mov	ebx,VMCS_EXIT_REASON
	vmread	rax,rbx
	push	rax

	movabs	rsi,offset fmt
	movabs	r15,offset bss_end
	mov	rdi,r15
	cld
	jmp	dump.1
dump.0:
	stosb
dump.1:
	lodsb
	test	al,al		
	jz	dump.11		#是0，结束
	test	al,0x80		#是控制符？
	jz	dump.0		#不是

	mov	cl,al
	mov	al,'='
	stosb
	mov	ax,0x7830	#0x
	stosw

	pop	rax
	test	cl,0x1		#16bit?
	jz	dump.2		#不是
	call	hexasc16
	jmp	dump.7
dump.2:
	test	cl,0x2		#32bit?
	jz	dump.3
	call	hexasc32
	jmp	dump.7
dump.3:
	call	hexasc64
dump.7:
	test	cl,0x8		#是换行？
	jz	dump.8		#不是
	mov	al,0xa		#写换行符
	stosb
	jmp	dump.1
dump.8:
	mov	ax,0x2020
	stosw
	jmp	dump.1
dump.11:
	stosb
dump.12:
	mov	rdi,r15
	mov	eax,1
	int	0x40
	jmp	$
	ret
	.global	fmt
fmt:
	.ascii	"EXIT_REASONS"
	.byte	0x80|B32
	.ascii	"EXIT_QUALIFICATION"
	.byte	0x80|B32|EOL
	.ascii	"GUEST_PHY_ADDR"
	.byte	0x80
	.ascii	"GUEST_LINEAR_ADDR"
	.byte	0x80|EOL
	.ascii	"GUEST_CR3"
	.byte	0x80
	.ascii	"GUEST_RIP"
	.byte	0x80|EOL
	.ascii	"VMEXIT_INSTRUCTION_LEN"
	.byte	0x80|B32
	.ascii	"VMEXIT_INTER_INFO"
	.byte	0x80|B32|EOL
	.ascii	"VMEXIT_INTERR_ERRCODE"
	.byte	0x80|B32
	.ascii	"IDT_VECTORING_ERRCODE"
	.byte	0x80|B32|EOL
	.ascii	"IDT_VECTORING_INFO_FIELD"	#,0x4408
	.byte	0x80|B32
	.ascii "VM_INSTRUCTION_ERR"
	.byte	0x80|B32|EOL
	.ascii	"GUEST_CR4"
	.byte	0x80|B32
	.ascii	"GUEST_CR0"
	.byte	0x80|B32|EOL
#	.ascii	"VMCS_VMEXIT_INTERRUPTION_INFO"
	.ascii	"VMCS_GUEST_RFLAGS"
	.byte	0x80|B32|EOL
	
	.byte	0x0
#
#rdi = vector
#
	.global	send_ipi1
send_ipi1:
	push	rax
	push	rsi
	push	rdi
	push	r8
	push	r9
	mov	r9,APIC_ICR_LO
	mov	r8,APIC_ICR_HI
	mov	eax,[APIC_ID]
	mov	[r8],eax
	or	edi,APIC_DEST_DESTFLD|APIC_LEVEL_ASSERT|APIC_DESTMODE_PHY|APIC_DELMODE_FIXED
	mov	[r9],edi
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rax
	ret
	.global	vmx_end
vmx_end:

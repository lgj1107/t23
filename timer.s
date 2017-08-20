	.text
	.include "apicreg.def"
	.include "regs.def"
	.include "misc.def"
	.include "mem.inc"
	.code64
	.intel_syntax noprefix
	.global	apic_timer,timer
apic_timer:
	push	rax
	push_fram
	call	get_lapic_id
	cmp	al,0
	ja	at.9
	
	swapgs
	mov	gs:[pcb_rsp],rsp
	mov	rbx,kernel_data_begin+kernel_tss
	mov	rax,[rbx+tss_rsp0]
	mov	gs:[pcb_rsp0],rax
	mov	gs:[pcb_rsp],rsp

	
	xor	eax,eax
	mov	al,[rip+index]
	xor	eax,1
	mov	[rip+index],al
	shl	eax,3
	movabs	rdi,offset pcb_addr
	mov	rax,[rdi + rax]
	mov	rsi,rax
	swapgs
	mov	ecx,IA32_KERNEL_GSBASE
	shld	rdx,rax,32
	wrmsr
	swapgs
	mov	rax,gs:[pcb_rsp0]
	mov	[rbx+tss_rsp0],rax
	mov	rsp,gs:[pcb_rsp]
	swapgs


	print_hex 11+128
at.9:
	pop_fram
	xor	eax,eax
	mov	[APIC_EOI],eax
	pop	rax
	iretq
timer:	push	rax
	push_fram
	inc	qword ptr [rip + tick8253]
	pop_fram
	xor	eax,eax
	mov	[APIC_EOI],eax
	pop	rax
	iretq
#
#rdi rsi rdx
#
	.global	create_user_task_pcb
create_user_task_pcb:
	mov	edi,0x400000
	xor	eax,eax
	mov	ecx,0x4000/8
	rep	stosq

	mov	eax,[rip+user_task]
	cmp	rax,0x33323130
	jne	2f	
1:
	mov	r8,0x400000
	mov	[rip+pcb_addr+8],r8	#暂时这样搞，PCB_ADDR中存储的是PCB和apic id，apic id
					#是决定在那个CPU上运行

	lea	r10,[r8+0x4000]		#user rsp3 address
	mov	[r8+pcb_rsp3],r10
	lea	r9,[r8+0x3000]		#user rsp0 address
	mov	[r8+pcb_rsp0],r9
	mov	rbp,rsp
	mov	rsp,r9

	push	SEL_UDATA
	push	r10
	push	0x202
	push	SEL_UCODE
	mov	rax,[rip+user_task+0x18]
	push	rax
	
	xor	eax,eax
	.rept	15
	push	rax
	.endr
	mov	[r8+pcb_rsp],rsp

	mov	rsp,rbp

	mov	rdi,r10
	lea	rsi,[rip+user_task]
	mov	ecx,[rip+user_task+0x10]	#user task size
	cld
	rep	movsb

2:
#	xor	eax,eax
	ret
get_tss_base_addr:

	xor	eax,eax
	str	ax

	mov	[rsi+tss_desc_base_15_0],ax
	shr	rax,16
	mov	[rsi+tss_desc_base_23_16],al
	mov	[rsi+tss_desc_base_31_24],ah
	shr	rax,16
	mov	[rsi+tss_desc_base_63_32],eax


	ret
index:
	.byte	0x0
tick8253:
	.quad	0x0
task_lock:
	.quad	0x0
task_queue:
	.quad	0x0
	.global	pcb_addr	
pcb_addr:
	.quad	0x0	#first task
	.quad	0x0	#
	.quad	0x0	#

#
#stack3		@stack3 top 0x5000
#rsv		@KB
#stack0		@stack top 0x3000
#
#tss
#gdtr
#gdt
#
	.include "apicreg.def"
	.include "regs.def"
	.include "misc.def"
	.include "mem.inc"
	.global start
	.intel_syntax noprefix
	.code64
	.text
	.code64
start:
	.long	0x55aa66bb
	.long	boot2_end - start
	.quad	offset ap_entry			#offset ap_entry
	.quad	boot2_end
	.quad	0x0				#kernel_phy
start.1:
	mov	rdi,kernel_virt_data_base
	mov	ecx,(8*1024*1024)/8
	xor	rax,rax
	rep	stosq
	
	mov	rdi,kernel_data_begin
	mov	r8,rdi
	movabs	rsi,offset gdt
	mov	ecx,temp_data0 - gdt
	rep	movsb


	lea	rsp,[r8+kernel_stk0]
	lea	rsi,[r8+kernel_gdtr]
	mov	[r8+0x48+2],r8			#gdt table address
	lgdt	[rsi]
	push	SEL_SCODE
	lea	rax,[rip+start64]
	push	rax
	retfq
start64:
	xor	eax,eax
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	mov	fs,ax
	mov	gs,ax

	movabs	rdi,kernel_idt
	mov	edx,0x188e
	movabs	rax,offset intx00
	mov	r8,rax
	mov	ebx,0x1fffff
	mov	ecx,20
s.2:
	shr	ebx,1
	jnc	s.3
	mov	[rdi],ax
	shr	rax,16
	mov	[rdi+int_gate_offset_31_16],ax
	shr	rax,16
	mov	[rdi+int_gate_offset_63_32],eax
	mov	[rdi+int_gate_seg_sel],dh
	mov	[rdi+int_gate_p_dpl_type],dl
	add	r8,4
	mov	rax,r8
s.3:
	lea	rdi,[rdi+16]
	loop	s.2

	movabs	rsi,offset idtr
	lidt	[rsi]

	push	rdx
	mov	dl,0xee
	set_gate 0x40,int0x40
	pop	rdx
.if 0
	mov	esi,0x90004
	xor	ecx,ecx
	mov	edx,ecx
	mov	dl,[esi-4]
	mov	eax,edx
	inc	dl
	mov	edi,0xb8000+160
	call	hex64
	mov	edi,0xb8000+160*2
2:
	mov	cl,5
1:
	lodsd
	call	hex32
	add	edi,2
	loop	1b
	add	edi,160
	sub	edi,45*2
	dec	dl
	jnz	2b
.endif
	set_gate 0x20,timer
	set_gate 0x21,keyb
	set_gate 0xf0,apic_timer
	set_gate 0xf1,apic_err
	set_gate 0xf2,apic_ici
	set_gate 0xff,apic_svr		#P6 family and pentium bit0 - bit3 hardwored to 1
#
#set TSS
#
	mov	rsi,kernel_data_begin+kernel_gdt+SEL_TSS
	mov	rdi,kernel_data_begin+kernel_tss
	mov	rax,rdi

	mov	[rsi+tss_desc_base_15_0],ax
	shr	rax,16
	mov	[rsi+tss_desc_base_23_16],al
	mov	[rsi+tss_desc_base_31_24],ah
	shr	rax,16
	mov	[rsi+tss_desc_base_63_32],eax

	mov	[rdi+tss_rsp0],rsp
	mov	al,-1
	mov	[rdi+tss_iomap_base],al

	mov	ax,SEL_TSS
	ltr	ax

	call	find_mptable

	mov	rax,kernel_data_begin
	shld	rdx,rax,32
	mov	ecx,IA32_FSBASE
	wrmsr
	mov	r8,rsp
	call	set_gs
	call	set_syscall
	call	enable_apic

	mov	eax,0				#AMD ebx=0x68747541 htuA
	cpuid					#ecx = 0x444d4163  DMAc
						#edx = 0x69746e65  itne
	cmp	ebx,0x68747541
	je	amd_cpu
	call	set_cr4_vmxe
	jmp	comm_set
amd_cpu:
	mov	byte ptr [rip+is_amd],1
	call	init_amd
comm_set:
	call	set_apic
	call	set_ioapic
	call	start_ap
wait_ap:
	test	byte ptr [rip+t_lock],1
	jnz	wait_ap
w.0:
	mov	rbx,kernel_data_begin + kernel_pcb
	mov	[rip+pcb_addr],rbx		#save kernel PCB
	call	create_user_task_pcb
jmp_ring3:
	push	SEL_UDATA
	mov	rax,kernel_data_begin + kernel_stk3
	push	rax
	push	0x202
	push	SEL_UCODE
	movabs	rax,offset ring3
	push	rax
	iretq
ring3:
	mov	eax,0x1
	cpuid
	mov	esi,ebx
	shr	esi,24
	mov	eax,8
	lea	rdi,[rip+msg1+26]
	int	0x40
	lea	rsi,[rip+msg1]
	mov	edi,3
	syscall
	mov	eax,0xb
	cpuid
	mov	esi,edx
	and	esi,0xff
	mov	eax,8
	lea	rdi,[rip+msg3+26]
	int	0x40
	lea	rsi,[rip+msg3]
	mov	edi,3
	syscall
1:
	rep
	nop
	jmp	1b
	.global	c_1
c_1:
	.byte	0x0
set_gate1:
	mov	[rdi],ax
	shr	rax,16
	mov	[rdi+int_gate_offset_31_16],ax
	shr	rax,16
	mov	[rdi+int_gate_offset_63_32],eax
	mov	[rdi+int_gate_seg_sel],dh
	mov	[rdi+int_gate_p_dpl_type],dl
	ret
#
#APIC ID 作为索引 计算AP CPU的核数据地址
#AMD A10 APIC ID是从0x10开始的，这样我设计的内核数据浪费很多内存
#还没想好该怎么弄，
#
ap_entry:
	call	get_lapic_id
	mov	rsi,kernel_data_begin
	imul	edi,eax,kernel_data_size
	lea	rdi,[rdi+rsi]
#	add	rdi,rsi
	mov	r15,rdi
#
#FS 基地址设置成CPU 数据起始地址
#
	mov	rax,r15
	shld	rdx,rax,32
	mov	ecx,IA32_FSBASE
	wrmsr
	
	mov	ecx,kernel_tss - kernel_gdt
	rep	movsb			#复制GDT 和 GDTR

	lea	rax,[r15 + kernel_gdt]	
	mov	[r15 +kernel_gdtr +2 ],rax
	
	lea	rsp,[r15 +kernel_stk0]
#
#设置TSS描述符 和TSS段
#
	lea	rdx,[r15 + kernel_gdt + SEL_TSS]
	lea	r14,[r15+kernel_tss]
	mov	rax,r14
	mov	byte ptr [rdx+tss_desc_limit_15_0],0x67
	mov	byte ptr [rdx+tss_desc_p_dpl_type],0x89
	mov	[rdx+tss_desc_base_15_0],ax
	shr	rax,16
	mov	[rdx+tss_desc_base_23_16],al
	mov	[rdx+tss_desc_base_31_24],ah
	shr	rax,16
	mov	[rdx+tss_desc_base_63_32],eax
	
	mov	[r14+tss_rsp0],rsp
	mov	word ptr [r14+tss_iomap_base],0xffff

	lea	rsi,[r15+kernel_gdtr]
	lgdt	[rsi]
	push	SEL_SCODE
	movabs	rax,offset flush_ap
	push	rax
	retfq
flush_ap:

	movabs	rsi,offset idtr
	lidt	[rsi]
	mov	ax,SEL_TSS
	ltr	ax
	
	call	enable_apic
	call	set_apic
	test	byte ptr [rip+is_amd],1
	jnz	f.0
	call	set_cr4_vmxe
	jmp	f.1
f.0:
	call	init_amd
f.1:
	mov	r8,rsp
	call	set_gs	
	call	set_syscall
	lock
	inc	byte ptr [rip+ap_cpu]
	
	mov	byte ptr [rip+t_lock],1
	sti
	lea	rdi,[rip+m1]
	push	rdi
	mov	esi,1
	call	test_and_set8

	call	get_lapic_id
	lea	rdi,[rip+msg2+10]
	call	hexasc8

	mov	eax,1
	lea	rdi,[rip+msg2]
	int	0x40
	pop	rdi
	mov	byte ptr [rdi],0
#	lock
	mov	byte ptr [rip+t_lock],0
1:
	pause
	jmp	1b
set_gs:
	call	get_lapic_id
	mov	rbx,kernel_data_begin + kernel_pcb
	mov	edx,kernel_data_size
	imul	rax,rdx
	add	rax,rbx
#	mov	[pcb_addr],rax		#save kernel PCB
	shld	rdx,rax,32
	mov	ecx,IA32_KERNEL_GSBASE
	wrmsr
	xor	eax,eax
	xor	edx,edx
	mov	ecx,IA32_GSBASE
	wrmsr
	swapgs
	mov	gs:[pcb_rsp0],r8
	swapgs
	ret
set_syscall:
	mov	ecx,IA32_STAR
	xor	eax,eax
	mov	edx,0x00230018
	wrmsr
	mov	eax,0x202
	mov	ecx,IA32_FMASK
	wrmsr
	movabs	rax,offset sys_call
	shld	rdx,rax,32
	mov	ecx,IA32_LSTAR
	wrmsr

	ret	
	.global	hex64,hex32
hex64:
	push	rax
	shr	rax,32
	call	hex32
	pop	rax
hex32:
	push	rax
	shr	rax,16
	call	hex16
	pop	rax
hex16:
	push	rax
	shr	ax,8
	call	hex8
	pop	rax
hex8:
	push	rax
	shr	al,4
	call	hex8.1
	pop	rax
hex8.1:
	and	al,0xf
	add	al,0x30
	cmp	al,0x39
	jbe	hex8.2
	add	al,0x7
hex8.2:
	mov	ah,2
	stosw		
	ret
	.global	set_cr4_vmxe
set_cr4_vmxe:
	mov	eax,1
	cpuid
	test	ecx,0x20		#VMX bit
	jz	no_vmx
	mov	rax,cr4
	or	rax,CR4_VMXE		#AMD CR4 no vmxe bit
	mov	cr4,rax
	ret
no_vmx:
	mov	eax,1
	lea	rdi,[rip+msg4]
	int	0x40
	ret

init_amd:
	mov	esi,APIC_ID
	mov	eax,1
	cpuid
	and	ebx,0xff000000			#AMD A10在A55BME主板上它的APIC ID会被设置成10 11 12 13，不方便管理
	mov	[rsi],ebx			#使用CPUID读出它真实的ID并写回去！
	ret
idtr:
	.word	256*16
	.quad	kernel_idt
cpu_count:
	.byte	0x0
	.global	t_lock
t_lock:
	.byte	0x1
t_lock1:
	.byte	0x1
	.p2align 4
gdt:
	.quad	0x0			#0
	.quad	0x00cf9a000000ffff	#0x8
	.quad	0x00cf92000000ffff	#0x10
	.quad	0x00209a0000000000	#0x18
	.quad	0x0000920000000000	#0x20
	.quad	0x0000f20000000000	#0x28
	.quad	0x0020fa0000000000	#0x30
#
#TSS
#
	.word	0x67			#limit 0 -15
	.word	0x0			#base address
	.byte	0x0			#base address 16 -23
	.byte	0x89			#p_dpl_type
	.byte	0x00			#g_avl_limit-16-19
	.byte	0x0			#byte 24 - 31
	.long	0x0			#base 32 - 63
	.long	0x0			#RSV
	
gdtr:	.word	gdtr - gdt
	.quad	gdt
temp_data0:
	.word	0x0
	.quad	0x0
ap_cpu:
	.byte	0x1
bsp_apic_id:
	.long	0x0
is_amd:
	.byte	0x0
	.global	cpu_flag
cpu_flag:
	.quad	0x0
	.global	m1
m1:.quad	0x0
m2:.quad	0x1
	.global	msg1
msg1:	.ascii	"CPUID EAX=0x1 INIT ID = 0x00"
	.byte	0xa,0x0
msg2:	.ascii	"APIC_ID 0x00"
	.byte	0xa,0x0	
msg3:	.ascii	"CPUID EAX=0xB X2APIC_ID 0x00"
	.byte	0xa,0x0	
msg4:	.ascii	"VMX NO support!!!"
	.byte	0xa,0x0	

int15_vector:			#real mode 
	.long	0x0

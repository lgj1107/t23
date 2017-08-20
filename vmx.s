
	.include "vmcs.def"
	.include "mem.inc"
	.include "regs.def"
	.include "misc.def"
	.intel_syntax noprefix

	.code64
.set	GUEST_IP,0x600 + 4
.set	GUEST_GDT_BASE,0x600 + 6
.set	GUEST_IDT_BASE,0x600 + 8
.set	GUEST_TSS_BASE,0x600 + 10

.set	GUEST_PML4E,0x3000000
.set	GUEST_PDPTE,GUEST_PML4E+0x1000
.set	GUEST_PDE,GUEST_PML4E+0x2000

.set	GUEST_MAX_PHY_MEM,0x2000000
	.global	start_vmx
start_vmx:
	.long	0x55aaaa55
	.long	vmx_end - start_vmx
	.long	offset start.0
	.long	0x0
start.0:
#
#set EPT page
#
	.global	set_ept
set_ept:
	mov	eax,offset EPT_PDPTE
	or	eax,EPT_READ|EPT_WRITE|EPT_EXECUTE_ACCESS
	mov	[EPT_PML4E],rax


	mov	esi,offset EPT_PDPTE
	mov	eax,offset EPT_PDE
	or	eax,EPT_READ|EPT_WRITE|EPT_EXECUTE_ACCESS
	mov	[rsi],rax
	mov	esi,offset EPT_PDE

	mov	eax,0x3fe00000|EPT_2M_PAGE|EPT_EXECUTE_ACCESS|EPT_WRITE|EPT_READ
	mov	[rsi+0xff8],rax

	mov	eax,EPT_2M_PAGE|EPT_EXECUTE_ACCESS|EPT_WRITE|EPT_READ
	mov	ecx,32
s.1:	
	mov	[rsi],rax
	add	rax,0x200000
	lea	rsi,[rsi+8]
	loop	s.1

	mov	ecx,IA32_FEATURE_CTL
	rdmsr
	test	al,1
	jnz	s.2
	or	eax,0x5
	wrmsr
s.2:
#
#initial VMCS region  (host guest)
#
	
	mov	ecx,IA32_VMX_BASIC
	rdmsr
	mov	[vmxon_region],eax
	mov	[vmcs_region],eax
	vmxon	[vmxon_ptr]
	vmclear [vmcs_ptr]
	vmptrld [vmcs_ptr]
#
#16 bit GUEST  state fields
#
	xor	eax,eax
	mov	ebx,VMCS_GUEST_CS_SEL
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_ES_SEL
	vmwrite rbx,rax
	mov	ebx,VMCS_GUEST_SS_SEL
	vmwrite rbx,rax
	mov	ebx,VMCS_GUEST_DS_SEL
	vmwrite rbx,rax
	mov	ebx,VMCS_GUEST_FS_SEL
	vmwrite rbx,rax
	mov	ebx,VMCS_GUEST_GS_SEL
	vmwrite rbx,rax
	mov	ebx,VMCS_GUEST_TR_SEL
	vmwrite rbx,rax
	mov	ebx,VMCS_GUEST_LDTR_SEL
	vmwrite rbx,rax
.if 0
	mov	ebx,VMCS_GUEST_IA32_SYSENTER_CS
	xor	eax,eax
	vmwrite	rbx,rax
.endif
#
#16 bit host state fields
#
	mov	eax,cs
	mov	ebx,VMCS_HOST_CS_SEL
	vmwrite	rbx,rax
	xor	eax,eax
	mov	ebx,VMCS_HOST_DS_SEL
	vmwrite	rbx,rax
	mov	ebx,VMCS_HOST_ES_SEL
	vmwrite	rbx,rax
	mov	ebx,VMCS_HOST_FS_SEL
	vmwrite	rbx,rax
	mov	ebx,VMCS_HOST_SS_SEL
	vmwrite	rbx,rax
	mov	ebx,VMCS_HOST_GS_SEL
	vmwrite	rbx,rax
	str	ax
	mov	ebx,VMCS_HOST_TR_SEL
	vmwrite	rbx,rax
#
#64bit control field
#
	xor	eax,eax
	mov	ebx,VMCS_ADDR_IOBMP_A
	vmwrite	rbx,rax
	mov	ebx,VMCS_ADDR_IOBMP_A_HIGH
	vmwrite	rbx,rax
	mov	ebx,VMCS_ADDR_IOBMP_B
	vmwrite	rbx,rax
	mov	ebx,VMCS_ADDR_IOBMP_B_HIGH
	vmwrite	rbx,rax
	mov	ebx,VMCS_ADDR_MSRBMP		#,0x2004
	mov	eax,offset vm_msr_bitmap
	vmwrite	rbx,rax

	mov	ebx,VMCS_EPT_PTR
	mov	eax,offset EPT_PML4E		#
	or	eax,0x1e
	vmwrite	rbx,rax

	mov	ebx,VMCS_EPT_PTR_HIGH
	xor	eax,eax
	vmwrite	rbx,rax

#
# 64-Bit Guest-State Fields 
#
	mov	ebx,VMCS_LINK_POINTER
	mov	rax,-1
	vmwrite	rbx,rax
	xor	eax,eax
	mov	ebx,VMCS_GUEST_IA32_DEBUGCTL
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_IA32_EFER
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_IA32_EFER_HIGH
	vmwrite	rbx,rax
.if 0
	mov	ebx,VMCS_VMENTRY_MSRLOAD_ADDR
	xor	eax,eax
	vmwrite	rbx,rax
	mov	ebx,VMCS_VMENTRY_MSRLOAD_ADDR_HIGH
	xor	eax,eax
	vmwrite	rbx,rax
	mov	ebx,VMCS_VMENTRY_INTR_INFO_FIELD
	vmwrite	rbx,rax
	mov	ebx,VMCS_VMENTRY_EXCEPTION_ERRCODE
	vmwrite	rbx,rax
	mov	ebx,VMCS_VMENTRY_INSTRUCTION_LEN
	vmwrite	rbx,rax
.endif

#
#64bit host state fields
#
	mov	ecx,MSR_EFER
	rdmsr
	mov	ebx,VMCS_HOST_IA32_EFER	
	vmwrite	rbx,rax

	mov	eax,edx
	mov	ebx,VMCS_HOST_IA32_EFER_HIGH
	vmwrite	rbx,rax

#
# 32-Bit Control Fields 
#
	mov	ecx,IA32_VMX_PINBASED_CTLS
	rdmsr
	or	eax,external_interrupt_exiting

	mov	ebx,VMCS_PIN_BASED_VMEXEC_CTL
	vmwrite	rbx,rax

	mov	ecx,IA32_VMX_PROCBASED_CTLS
	rdmsr
	and	eax,~(cr3_load_exiting|cr3_store_exiting)
	or	eax,0x80000000|use_msr_bitmaps			#activate secondary control
#	or	eax,0x80000000|hlt_exiting			#activate secondary control
	mov	ebx,VMCS_PROC_BASED_VMEXEC_CTL
	vmwrite	rbx,rax

	mov	ebx,VMCS_EXCEPTION_BITMAP
	xor	eax,eax
	vmwrite	rbx,rax
	
	mov	ebx,VMCS_VMENTRY_INTR_INFO_FIELD
	vmwrite rbx,rax
	
	mov	ecx,IA32_VMX_PROCBASED_CTLS2
	rdmsr
	or	eax,unrestricted_guest|enable_ept
	mov	ebx,VMCS_PROC_BASED_VMEXEC_CTL2
	vmwrite	rbx,rax
	
	mov	ecx,IA32_VMX_EXIT_CTLS
	rdmsr
	or	eax,host_addr_space_size|ack_interrupt_on_exit
	mov	ebx,VMCS_VMEXIT_CTL
	vmwrite	rbx,rax

	mov	ecx,IA32_VMX_ENTRY_CTLS
	rdmsr

	and	eax,~ia32e_mode_guest
	or	eax,entry_load_ia32_efer
	mov	ebx,VMCS_VMENTRY_CTL
	vmwrite	rbx,rax

	mov	eax,2
	mov	ebx,VMCS_CR3_TARGET_COUNT
	vmwrite rbx,rax

	mov	ebx,VMCS_VMEXIT_MSR_LOAD_COUNT
	xor	eax,eax
	vmwrite	rbx,rax

#
# 32-Bit Guest-State Fields 
#
	mov	eax,0xffff
	mov	ebx,VMCS_GUEST_ES_LIMIT
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_CS_LIMIT
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_DS_LIMIT
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_FS_LIMIT
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_SS_LIMIT
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_GS_LIMIT
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_LDTR_LIMIT
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_TR_LIMIT
	vmwrite	rbx,rax
.if 1
#	mov	eax,256*8-1
#	mov	rbx,VMCS_GUEST_GDTR_LIMIT
#	vmwrite rbx,rax

.endif
	mov	eax,0x7ff
	mov	ebx,VMCS_GUEST_IDTR_LIMIT
	vmwrite rbx,rax

	mov	eax,0x9b
	mov	ebx,VMCS_GUEST_CS_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	eax,0x93
	mov	ebx,VMCS_GUEST_ES_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_SS_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_DS_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_FS_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_GS_ACCESS_RIGHTS
	vmwrite	rbx,rax
	mov	eax,0x82
	mov	ebx,VMCS_GUEST_LDTR_ACCESS_RIGHTS
	vmwrite rbx,rax
	mov	eax,0x8b		#0x8b
	mov	ebx,VMCS_GUEST_TR_ACCESS_RIGHTS	
	vmwrite rbx,rax
	mov	ebx,VMCS_GUEST_IA32_SYSENTER_CS
	xor	eax,eax
	vmwrite	rbx,rax

.if 0	
	mov	ebx,VMCS_GUEST_INTERRUPTIBILITY_STATE
	vmwrite rbx,rax
	mov	ebx,VMCS_GUEST_ACTIVITY_STATE
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_SMBASE
	mov	eax,0xa0000
	vmwrite	rbx,rax
.endif
#
# 32-Bit Host-State Fields 
#

#
# Natural-Width Control Fields 
#
#cr4 cr0 shadow ,intel manual poweron value is 0x0 and 0x60000010
	mov	ebx,VMCS_CR0_READ_SHADOW
	mov	eax,0x60000010
	vmwrite	rbx,rax

	mov	ebx,VMCS_CR0_GUESTHOST_MASK	
	vmwrite	rbx,rax

	mov	ebx,VMCS_CR4_READ_SHADOW
	xor	eax,eax
	vmwrite	rbx,rax

	mov	ebx,VMCS_CR4_GUESTHOST_MASK	
	mov	eax,0x2000
	vmwrite	rbx,rax

	mov	ebx,VMCS_CR3_TARGET_VALUE_0
	xor	eax,eax
	vmwrite	rbx,rax

	mov	ebx,VMCS_CR3_TARGET_VALUE_1
	xor	eax,eax
#	mov	eax,PAGE_PML4
	vmwrite	rbx,rax

#
# Natural-Width Read-Only Fields 
#
#
# Natural-Width Guest-State Fields 
#
	mov	eax,0x00000020
	mov	ebx,VMCS_GUEST_CR0
	vmwrite	rbx,rax

	xor	eax,eax
	mov	ebx,VMCS_GUEST_CR3
	vmwrite	rbx,rax

	mov	eax,0x00002000
	mov	ebx,VMCS_GUEST_CR4
	vmwrite	rbx,rax

	mov	eax,0x2
	mov	ebx,VMCS_GUEST_RFLAGS
	vmwrite	rbx,rax

	mov	ebx,VMCS_GUEST_RIP
	movzx	eax,word ptr [GUEST_IP]
	vmwrite	rbx,rax

	xor	eax,eax
	mov	ebx,VMCS_GUEST_TR_BASE
#	movzx	eax,word ptr [GUEST_TSS_BASE]
	vmwrite	rbx,rax

	xor	eax,eax
	mov	ebx,VMCS_GUEST_GDTR_BASE
	vmwrite	rbx,rax
	mov	ebx,VMCS_GUEST_IDTR_BASE
	vmwrite rbx,rax

	mov	eax,0x7c00
	mov	ebx,VMCS_GUEST_RSP
	vmwrite	rbx,rax


#
# Natural-Width Host-State Fields 
#
	mov	rax,cr0
	mov	ebx,VMCS_HOST_CR0
	vmwrite	rbx,rax

	mov	rax,cr3
	mov	ebx,VMCS_HOST_CR3
	vmwrite	rbx,rax
	
	mov	rax,cr4
	mov	ebx,VMCS_HOST_CR4
	vmwrite	rbx,rax

	xor	eax,eax
	mov	ebx,VMCS_HOST_GS_BASE
	vmwrite	rbx,rax
	mov	ebx,VMCS_HOST_FS_BASE
	vmwrite	rbx,rax

	mov	rax,kernel_data_begin+kernel_tss
	mov	ebx,VMCS_HOST_TR_BASE
	vmwrite	rbx,rax

	mov	rax,kernel_data_begin+kernel_gdt
	mov	ebx,VMCS_HOST_GDTR_BASE
	vmwrite	rbx,rax
	
	mov	rax,kernel_idt
	mov	ebx,VMCS_HOST_IDTR_BASE
	vmwrite	rbx,rax
	
	mov	rax,rbp
	mov	ebx,VMCS_HOST_RSP
	vmwrite	rbx,rax

	movabs	rax,offset vm_exit
	mov	ebx,VMCS_HOST_RIP
	vmwrite	rbx,rax
	ret
	.global	hexasc64,hexasc32,hexasc16
hexasc64:
	push	rax
	shr	rax,32
	call	hexasc32
	pop	rax
hexasc32:
	push	rax
	shr	eax,16
	call	hexasc16
	pop	rax
hexasc16:
	push	rax
	shr	eax,8
	call	hexasc8
	pop	rax
hexasc8:
	push	rax
	shr	al,4
	call	hexasc8.1
	pop	rax
hexasc8.1:
	and	al,0xf
	add	al,0x30
	cmp	al,0x39
	jbe	hexasc8.2
	add	al,0x7
hexasc8.2:
	stosb		
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

vmxon_ptr:
	.quad	vmxon_region
vmcs_ptr:
	.quad	vmcs_region
.global	bss_end	
	.bss
	.p2align 12
.if 1
vmxon_region:
	.space	0x1000
vmcs_region:
	.space	0x1000
.endif 
EPT_PML4E:
	.space	0x1000
EPT_PDPTE:	
	.space	0x1000
EPT_PDE:
	.space	0x1000
EPT_TMP_PDPTE:
	.space	0x1000
EPT_TMP_PDE:
	.space	0x1000
vm_msr_bitmap:
	.space	0x1000
vm_exit_msr_load:
	.space	0x1000
vm_entry_msr_load:
	.space	0x1000

bss_end:

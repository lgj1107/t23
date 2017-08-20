	.include "apicreg.def"
	.include "regs.def"
	.include "misc.def"
	.global	set_apic
	.code64
	.intel_syntax noprefix
set_apic:
	mov	esi,APIC_LVT_LINT0
	mov	eax,APIC_LVT_DM_EXTINT
	mov	[rsi],eax
	mov	esi,APIC_LVT_LINT1
	mov	eax,APIC_LVT_DM_NMI
	mov	[rsi],eax
.if 1
	xor	eax,eax
	mov	esi,APIC_ESR
	mov	[rsi],eax
	
	mov	esi,APIC_LVT_ERR
	mov	eax,0xf1
	mov	[rsi],eax

	mov	esi,APIC_INITIAL_COUNT_TIMER
	mov	eax,0xfff0
	mov	[rsi],eax
	mov	esi,APIC_DIVISOR_CONFIG_TIMER
	mov	eax,APIC_TDCR_4
	mov	[rsi],eax

	mov	esi,APIC_LVT_TIMER
	mov	eax,0xf0|APIC_LVTT_TM_PERIODIC
#	mov	eax,0xf0|APIC_LVTT_TM_PERIODIC|APIC_LVTT_TGM	#I5 3450 不能设置
	mov	[rsi],eax

	mov	esi,APIC_TPR
	xor	eax,eax
	mov	[rsi],eax
	
#	mov	esi,APIC_SVR
#	mov	eax,[rsi]
#	mov	al,0xff
#	mov	[rsi],eax

	xor	eax,eax
	mov	[APIC_EOI],eax
.endif
	ret

	.global	set_ioapic
set_ioapic:
	mov	esi,IOAPIC_REG_SEL
	mov	edi,IOAPIC_WIN
	mov	eax,IOAPIC_REDTBL2	#timer
	mov	[rsi],eax
	mov	eax,0x20
	mov	[rdi],eax
	mov 	eax,IOAPIC_REDTBL2+1
	mov 	[rsi],eax
	xor	eax,eax
	mov	[rdi],eax

	mov	eax,IOAPIC_REDTBL1	#KEYBOARD
	mov	[rsi],eax
	mov	eax,0x21
	mov	[rdi],eax
	mov 	eax,IOAPIC_REDTBL1+1
	mov 	[rsi],eax
	xor	eax,eax
#	mov	eax,0x0f<<24
	mov	[rdi],eax
	ret
	.global	start_ap,enable_apic
enable_apic:
	mov	ecx,MSR_APICBASE
	rdmsr
	bts	eax,11
	wrmsr

	mov	edi,APIC_SVR
	mov	eax,[rdi]
	bts	eax,8		#APIC SVR enable bit
	or	al,0xff		#vector 0xff
	mov	[rdi],eax
	ret

start_ap:	
	mov	esi,APIC_ICR_LO
	mov	edi,APIC_ICR_HI
	xor	ebx,ebx
	mov	[edi],ebx
#INIT IPI LEVEL域 P4 and Xeon 永远是1
#Trigger Mode P4 and Xeon 永远是0
#I7 6700, T1500,i7 3840MQ 返回值是0XC0500，而BOCHS QEMU返回0xc4500 
#AP CPU 启动过程不考虑P6及其以下的CPU。
#IPI 按INTEL 的手册 INIT-SIPI-SIPI，但是在实际试用过程中可以
#INIT-SIPI 试过几台电脑都可以完美启动AP CPU
#
	mov	eax,APIC_DEST_ALLESELF|APIC_LEVEL_ASSERT|APIC_TRIGMOD_EDGE|APIC_DELMODE_INIT
	mov	[esi],eax
	mov	ecx,1024
	call	delay
.if 0
#	mov	[edi],ebx
	mov	eax,APIC_DEST_ALLESELF|APIC_DELMODE_STARTUP|0x9f
	mov	[esi],eax
	mov	ecx,4096
	call	delay
.endif
1:
	mov	eax,[rsi]
	test	eax,APIC_DELSTAT_PEND
	jnz	1b
	
#	mov	[edi],ebx
	mov	eax,APIC_DEST_ALLESELF|APIC_DELMODE_STARTUP|0x9f
	mov	[esi],eax
	mov	ecx,1024
	call	delay
	
	ret
delay:
	in	al,0x84
	loop	delay
	ret
	.global	send_ipi
send_ipi:
	push	rax
	push	rsi
	push	rdi
	mov	esi,APIC_ICR_LO
	mov	edi,APIC_ICR_HI
	mov	eax,2 << 24
	mov	[rdi],eax
	mov	eax,APIC_DEST_DESTFLD|APIC_LEVEL_ASSERT|APIC_DESTMODE_PHY|APIC_DELMODE_FIXED|0xf2
	mov	[rsi],eax
	pop	rdi
	pop	rsi
	pop	rax
	ret
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
	call	get_lapic_id
	shl	eax,24
	mov	[r8],eax
	or	edi,APIC_DEST_DESTFLD|APIC_LEVEL_ASSERT|APIC_DESTMODE_PHY|APIC_DELMODE_FIXED
	mov	[r9],edi
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rax
	ret
	.global	get_lapic_id
get_lapic_id:
	mov	eax,[APIC_ID]
	shr	eax,APIC_ID_SHIFT
	ret

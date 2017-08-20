
	.set	mp_sig,	0x5f504d5f	# _MP_
	.set	mpcth_sig,0x504d4350	#PCMP
## EBDA is @ 40:0e in real-mode terms 
	.set	EBDA_POINTER,0x040e		## location of EBDA pointer 
#	
## CMOS 'top of mem' is @ 40:13 in real-mode terms
#	
	.set	TOPOFMEM_POINTER,0x0413		## BIOS: base memory size 
	.set	DEFAULT_TOPOFMEM,0xa0000

	.set	BIOS_BASE,0xf0000
	.set	BIOS_BASE2	,	0xe0000
	.set	BIOS_SIZE	,	0x10000
	.set	ONE_KBYTE	,	1024

.set GROPE_AREA1,	0x80000
.set GROPE_AREA2,	0x90000
.set GROPE_SIZE	,	0x10000

.set PROCENTRY_FLAG_EN,	0x01
.set PROCENTRY_FLAG_BP,	0x02
.set IOAPICENTRY_FLAG_EN,	0x01

.set MAXPNSTR	,	132
#
# MP Floating Pointer Structure 
#

	.set	MPFPS_signature,0
    	.set	MPFPS_physical_addr_pointer,4
	.set	MPFPS_length,8
	.set	MPFPS_spec_rev,9
	.set	MPFPS_checksum,10
	.set	MPFPS_MP_feature_byte1,11
	.set	MPFPS_MP_feature_byte2,12
	.set	MPFPS_MP_feature_byte3,13
	.set	MPFPS_MP_feature_byte4,14
	.set	MPFPS_MP_feature_byte5,15
#
#MP Configuration Table Header
#
	.set	MPCTH_BASE_TABLE_LENGTH,0x4
	.set	MPCTH_OEMID_STRING,0x8
	.set	MPCTH_PRODUCT_ID,0x10
	.set	MPCTH_entry_count,0x22
#
#
#	
	.text
	.code64
	.intel_syntax noprefix
	.global	find_mptable
find_mptable:
	movzx	edi,word ptr[0x40e]
	shl	edi,4
	mov	eax,mp_sig
	mov	ecx,1024/4
	cld
	repne	scasd
	jz	find_ok
	movzx	edi,word ptr [0x413]
	shl	edi,10			#
	mov	ecx,1024/4
	repnz	scasd
	jz	find_ok
	mov	edi,0xf0000
	mov	ecx,BIOS_SIZE/4
	repnz	scasd
	jz	find_ok
1:
	mov	eax,1
	lea	rdi,[rip+msg10]
	int	0x40
	call	find_acpi
	jc	f_end
	hlt
find_acpi:
	stc
	ret
find_ok:
	sub	edi,4
	mov	al,[rdi+MPFPS_spec_rev]
	add	al,0x30
	mov	[rip+msg0+32],al
	push	rdi
	mov	eax,7
	mov	esi,edi
	lea	rdi,[rip+msg0+17]
	int	0x40
	mov	eax,1
	lea	rdi,[rip+msg0]
	int	0x40
	pop	rdi

	test	byte ptr [rdi+MPFPS_MP_feature_byte2],0x80
	jz	no_imcrp
	mov	al,0x70		#IMCR
	out	0x22,al
	mov	al,1
	out	0x23,al		#mask 8259
no_imcrp:
    	mov	esi,[rdi+MPFPS_physical_addr_pointer]
	mov	rbx,rsi
	lea	rsi,[rsi+MPCTH_OEMID_STRING]
	lea	rdi,[rip+m111]
	cld
	mov	ecx,8
3:	
	lodsb
	test	al,al
	jz	4f
	stosb
	loop	3b
4:
#
#AMI BIOS 这里发神经不用的字节全是填充的0。不是ASCII码
#
	lea	rsi,[rbx+MPCTH_PRODUCT_ID]
	lea	rdi,[rip+m222]
	mov	ecx,12
1:	
	lodsb
	test	al,al
	jz	2f
	stosb
	loop	1b
2:
#	mov	eax,[rbx+MPCTH_BASE_TABLE_LENGTH]
#	mov	edi,0xb8000+160*11+64
#	call	hex32
	mov	eax,1
	lea	rdi,[rip+msg11]
	int	0x40

	mov	eax,1
	lea	rdi,[rip+msg12]
	int	0x40
f_end:
	ret
msg12:	.ascii	"PRODUCT ID = "
m222:	.ascii	"            "
	.byte	0xa,0xa,0x0
msg11:	.ascii	"OEM ID STRING="
m111:	.ascii	"         "
	.byte	0xa,0x0
	
msg10:
	.asciz	"No MP TABLE !!!! \n"
msg0:
	.ascii "MP TBALE FOUND@0x00000000 VER 1.0"
	.byte	0xa,0x0

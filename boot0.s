	.global start
	.include "regs.def"
	.code16
	.intel_syntax noprefix
start:
	cli
	xor	cx,cx
	mov	ds,cx
	mov	es,cx
	mov	ss,cx
	mov	sp,0x7c00
	mov	si,sp
	mov	di,0x600
	inc	ch
	cld
	rep	movsw
#	jmp	main - 0x7c00 +0x600
	ljmp	0:main -start+0x600
main:
.if 1
	push	dx
	push	es
	push	ds
	mov	ax,0x9000
	mov	es,ax
	mov	di,4			#0x90000 处放的是int 0x15 执行次数
	xor	ebx,ebx
m.0:
	mov	ecx,20			#ACPI 3.0 列表条目长度扩展到24个字节长，3.0以前是20个字节
					#在第一次成功调用后CL中返回实际储存在ES：DI中的字节数
#ECX中的值还是设置成20比较靠谱，测试了一下，设置成24不能返回8G以上的内存的条目
#M17X 微星Z170 都是16G内存。acpi 5.0 中也是说的20 bytes
#
	mov	edx,0x534d4150		#SMAP
	mov	eax,0xe820
	int	0x15
	jc	m.2			#CF=1 出错
#	mov	edx,0x534d4150		#SMAP
	cmp	eax,0x534d4150
	jne	m.2
	test	ebx,ebx
	jz	m.2
	add	di,cx
	inc	byte ptr es:[0x0]
	jmp	m.0
m.2:
	mov	es:[2],cx
.if 0
	push	es
	pop	ds
	mov	bx,0xb800
	mov	es,bx
	xor	ax,ax
	mov	fs,ax
	lds	si,fs:[0x41*4]
	mov	ax,[si]
	mov	di,160*2
	call	hex16
.endif
	pop	ds
	pop	es
	pop	dx

.endif
main.1:
	sti
	test	dl,0x80
	jz	read_floppy

	mov	dl,0x80
	lea	si,disk_pack
	mov	ah,0x42
	int	0x13

	jmp	main.9
read_floppy:

	mov	ax,0x1000
	mov	es,ax
	mov	si,8
	call	intx13
main.9:
	mov	ax,0x1000
	mov	ds,ax

	xor	ax,ax
	mov	es,ax

	mov	di,0x800
	xor	si,si
	mov	cx,(512*17+512*18*3)/2
	cld
	rep	movsw
main.10:
	xor	ax,ax
	mov	ds,ax

	mov	bx,0x800
	jmp	bx
	.att_syntax prefix
	jmp	*(%bx)
	.intel_syntax noprefix
	jmp	.
	

/*
 * BIOS call "INT 0x13 Function 0x2" to read sectors from disk into memory
 *	Call with	%ah = 0x2
 *			%al = number of sectors
 *			%ch = cylinder
 *			%cl = sector (bits 6-7 are high bits of "cylinder")
 *			%dh = head
 *			%dl = drive (0x80 for hard disk, 0x0 for floppy disk)
 *			%es:%bx = segment:offset of buffer
 *	Return:
 *			%al = 0x0 on success; err code on failure
 */
intx13:
	xor	bx,bx
#	mov	dh,bl
	mov	al,17
	mov	cx,2
int.1:
	mov	dh,[head]
	mov	ch,[cyl]
	xor	byte ptr [head],1
	jnz	int.2
	inc	byte ptr [cyl]
int.2:
	mov	ah,2
	int	0x13

	mov	al,18
	mov	cl,1
	mov	bx,[load_addr]
	mov	di,0x512*18
	add	[load_addr],di
	dec	si
	jnz	int.1
	ret	
head:
	.byte	0x0
cyl:
	.byte	0x0
load_addr:
	.word	512*17
count:
	.byte	0x4
wheel:
	.byte	'|
	.byte	'\\
	.byte	'-
	.byte	'/

hex16:
	push	ax
	shr	ax,8
	call	hex8
	pop	ax
hex8:
	push	ax
	shr	al,4
	call	hex8.1
	pop	ax
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

#
#BIOS int 0x13 ah=0x42 disk address packet structure
#
#
	.p2align 4
disk_pack:
	.byte	0x10		#struct size (always 16 bytes ??)
	.byte	0		#reserved  0
	.word	18*4		#sector count read ,on some BIOS you can specify only
				#up to 127 sector (0x7f).BIOS int 0x13 places here number of 
				#sectors actually read
	.word	0x0		#offset
	.word	0x1000		#segment
	.long	0x1		#sector number to read 
	.long	0x0		#use only in LBA48
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
.if 1
#这个MBR是伪造的！！！
#只是为了欺骗BIOS 把USB当成一个硬盘
#方便试用 int 0x13 ah=0x42
.org	0x1be
	.byte	0x80		#活动分区标志，80激活分区
	.byte	0x0		#分区起始磁头号
	.byte	0x1		#分区起始扇区号
	.byte	0x0
	.byte	0xa5		#系统标志,1=fat12,4=fat16,0xc=win95 fat32 0xa5 BSD
	.byte	0xfe,0xff,0xff
	.long	0x0		#
	.long	50000		#本分区总扇区数

	.fill	64-16,1,0
.endif
	.org	510
	.word	0xaa55
	.bss
PML4E:
	.space	0x1000
PDPTE:
	.space	0x1000
PDPDE:
	.space	0x1000	

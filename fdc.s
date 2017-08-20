

readcmd: .byte 0xe6,0,0,0,0,2,18,0x1b,0xff
#
#	 step 5 load remaining 15 sectors off disk 
#
dodisk:
	mov	edi,0x70000
	mov	ebx,2
	mov	al,0x20		# do a eoi
	out	0x20,al
	jmp	$+2
	mov	al,0x7
	out	0x21,al
	jmp	$+2
 8:
	movabs	r8,offset readcmd
	mov	[r8+4],bl
	mov	ecx,edi

#
#	 Set read/write bytes 
#
	mov	edx,0x0c	# outb(0xC,0x46); outb(0xB,0x46);
	mov	al,0x46
	out	dx,al
	jmp	$+2
	dec	dl
	out	dx,al
#
#	 Send start address 
#
	.att_syntax 
	movb	$0x04,%dl	# outb(0x4, addr);
	movb	%cl,%al
	outb	%al,%dx
	NOP
	movb	%ch,%al		# outb(0x4, addr>>8);
	outb	%al,%dx
	NOP
	rorl	$8,%ecx		# outb(0x81, addr>>16);
	movb	%ch,%al
	outb	%al,$0x81
	NOP

	/* Send count */
	movb	$0x05,%dl	# outb(0x5, 0);
	xorl	%eax,%eax
	outb	%al,%dx
	NOP
	movb	$2,%al		# outb(0x5,2);
	outb	%al,%dx
	.intel_syntax noprefix
	jmp	$+2
#
#	 set channel 2 
#
	# movb	$2,%al		# outb(0x0A,2);
	out	0xa,al
	jmp	$+2
#
#	 issue read command to fdc */
#
	mov	dx,0x3f4
#	movl	$readcmd,%esi
	movabs	r8,offset readcmd
	mov	ecx,9
 2:
	in	al,dx
	jmp	$+2
	test	al,0x80
	jz	2b
	inc	dl
	mov	al,[r8]
	out	dx,al
	jmp	$+2
	inc	r8
	dec	dl
	loop	 2b
#
#	 watch the icu looking for an interrupt signalling completion */
#
	mov	edx,0x20
2:	mov	al,0xf
	out	dx,al
	jmp	$+2
	inb	al,dx
	jmp	$+2
	and	al,0x7f
	cmp	al,6
	jne	2b
	mov	al,0x20		# do a eoi
	outb	dx,al
	jmp	$+2
.att_syntax 
	movl	$0x3f4,%edx
	xorl	%ecx,%ecx
	movb	$7,%cl
 2:	inb	%dx,%al
	nop
	andb	$0xC0,%al
	cmpb	$0xc0,%al
	jne	2b
	inc	%dx
	.intel_syntax noprefix
	in	al,dx
	dec	dl
	loop	2b
#
#	# extract the status bytes after the read. must we do this? */
#
	add	edi,0x200		# next addr to load to
	inc	bl
	cmp	bl,1
	jle	8b
	ret	

	jmp	$
	

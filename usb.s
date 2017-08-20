	.macro pci_bread reg
	.set	dev,29<<11
	mov	eax,0x80000000|dev|\reg
	out	dx,eax
	add	dl,4
	and	al,0xfc
	add	dl,al
	in	al,dx
	.endm

	.intel_syntax noprefix
	.code64
	.text
	.code64
	.global	probe_pci
probe_pci:
	pci_bread 0
	mov	edi,0
	
	ret


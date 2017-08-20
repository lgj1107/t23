	.intel_syntax noprefix
	.code64
	.global	start
#
#INT 0x15 0x88 0xE801 0xE802
#现代PC很多用这中断探测内存容量，但是在VT中这影响内存管理，因此拦截掉
#本例中只允许0x88执行，其他2个直接废掉，
#0x88返回最大内存64M，因此EPT映射了64M 这样简单处理 一切正常，
#目前只试用了NETBSD 1.0和2.0 能正常启动！

	.text
start:
	.ascii	"0123"
	.ascii	"4567"
	.quad	0x0
	.quad	t_end - start		#
	.quad	offset startu
startu:
	xor	eax,eax
	xor	eax,eax
	lea	rsi,[rip+msg1]
	mov	edi,3
	syscall
	
	jmp	$
msg1:
	.ascii	"fjjalskdla"
	.byte	0xa
	.byte	0x0
t_end:	

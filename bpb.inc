.if 1
start:
	jmp start.1
	nop
oemid:	.ascii "MSDOS5.0"
#
#0xb	standard BIOS parameter block BPB
#
bpb:	.word	512			#sector size		#0xb
	.byte	0x1			#sector/clustor
	.word	0x1			#reserved sectors
	.byte	0x2			#number of FATs
	.word	224			#root entries
	.word	2880			#small sectors
	.byte	0xf0			#media type W		#0x15
	.word	0x9			#sectors/fat		#
	.word	18			#sectors per track 	#
	.word	2			#number of heads
	.long	0x0			#hidden sectors
	.long	0x0			#large sectors		#32
#
#extended BPB for FAT12 /FAT16
#
	.byte	0x0			#BS_Drv_num intx13
	.byte	0x0			#rsv
	.byte	0x29			#BS_Bootsig		38
	.long	0x0			#BS_VolID		39
	.ascii	"12345678901"		#BS_VolLabel		43
	.ascii	"FAT12   "		#BS_FilesysType		54
start.1:
.endif

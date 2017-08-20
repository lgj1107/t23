# PCI config registers 

	.set	 PCI_CBMEM,0x10	# configuration base memory #

	.set	 PCI_INTERFACE_OHCI,0x10
#
# OHCI registers 
#
	.set	OHCI_REVISION,0x00,# OHCI revision # #
	#	.set	OHCI_REV_LO(rev),((rev)&0xf)
	#.set	OHCI_REV_HI(rev),(((rev)>>4)&0xf)
	#.set	OHCI_REV_LEGACY(rev),((rev) & 0x100)

	.set	OHCI_CONTROL,0x04
	.set	OHCI_CBSR_MASK,0x00000003 # Control/Bulk Service Ratio #
	.set	OHCI_RATIO_1_1,0x00000000
	.set	OHCI_RATIO_1_2,0x00000001
.set  OHCI_RATIO_1_3,0x00000002
.set  OHCI_RATIO_1_4,0x00000003
.set  OHCI_PLE,0x00000004 # Periodic List Enable #
.set  OHCI_IE,0x00000008 # Isochronous Enable #
.set  OHCI_CLE,0x00000010 # Control List Enable #
.set  OHCI_BLE,0x00000020 # Bulk List Enable #
.set  OHCI_HCFS_MASK,0x000000c0 # HostControllerFunctionalState #
.set  OHCI_HCFS_RESET,0x00000000
.set  OHCI_HCFS_RESUME,0x00000040
.set  OHCI_HCFS_OPERATIONAL,0x00000080
.set  OHCI_HCFS_SUSPEND,0x000000c0
.set  OHCI_IR,,0x00000100 # Interrupt Routing #
.set  OHCI_RWC,0x00000200 # Remote Wakeup Connected #
.set  OHCI_RWE,0x00000400 # Remote Wakeup Enabled #
.set OHCI_COMMAND_STATUS,0x08
.set  OHCI_HCR,0x00000001 # Host Controller Reset #
.set  OHCI_CLF,0x00000002 # Control List Filled #
.set  OHCI_BLF,0x00000004 # Bulk List Filled #
.set  OHCI_OCR,0x00000008 # Ownership Change Request #
.set  OHCI_SOC_MASK,0x00030000 # Scheduling Overrun Count #
.set OHCI_INTERRUPT_STATUS,0x0c
.set  OHCI_SO,0x00000001 # Scheduling Overrun #
.set  OHCI_WDH,0x00000002 # Writeback Done Head #
.set  OHCI_SF,0x00000004 # Start of Frame #
.set  OHCI_RD,0x00000008 # Resume Detected #
.set  OHCI_UE,0x00000010 # Unrecoverable Error #
.set  OHCI_FNO,0x00000020 # Frame Number Overflow #
.set  OHCI_RHSC,0x00000040 # Root Hub Status Change #
.set  OHCI_OC,0x40000000 # Ownership Change #
.set  OHCI_MIE,0x80000000 # Master Interrupt Enable #
.set OHCI_INTERRUPT_ENABLE,0x10
.set OHCI_INTERRUPT_DISABLE,0x14
.set OHCI_HCCA,0x18
.set OHCI_PERIOD_CURRENT_ED,0x1c
.set OHCI_CONTROL_HEAD_ED,0x20
.set OHCI_CONTROL_CURRENT_ED,0x24
.set OHCI_BULK_HEAD_ED,0x28
.set OHCI_BULK_CURRENT_ED,0x2c
.set OHCI_DONE_HEAD,0x30
.set OHCI_FM_INTERVAL,0x34
.set  OHCI_GET_IVAL(s),((s) & 0x3fff)
.set  OHCI_GET_FSMPS(s),(((s) >> 16) & 0x7fff)
.set  OHCI_FIT,0x80000000
.set OHCI_FM_REMAINING,0x38
.set OHCI_FM_NUMBER,0x3c
.set OHCI_PERIODIC_START,0x40
.set OHCI_LS_THRESHOLD,0x44
.set OHCI_RH_DESCRIPTOR_A,0x48
#.set  OHCI_GET_NDP(s),((s) & 0xff)
.set  OHCI_PSM,0x0100     # Power Switching Mode #
.set  OHCI_NPS,0x0200,   # No Power Switching #
.set  OHCI_DT,0x0400     # Device Type #
.set  OHCI_OCPM,0x0800     # Overcurrent Protection Mode #
.set  OHCI_NOCP,0x1000     # No Overcurrent Protection #
.set  OHCI_GET_POTPGT(s),((s) >> 24)
.set OHCI_RH_DESCRIPTOR_B,0x4c
.set OHCI_RH_STATUS,0x50
.set  OHCI_LPS,0x00000001 # Local Power Status #
.set  OHCI_OCI,0x00000002 # OverCurrent Indicator #
.set  OHCI_DRWE,0x00008000 # Device Remote Wakeup Enable #
.set  OHCI_LPSC,0x00010000 # Local Power Status Change #
.set  OHCI_CCIC,0x00020000 # OverCurrent Indicator Change #
.set  OHCI_CRWE,0x80000000 # Clear Remote Wakeup Enable #
.set OHCI_RH_PORT_STATUS(n),(0x50 + (n)*4) # 1 based indexing #

.if 0
.set OHCI_LES (OHCI_PLE | OHCI_IE | OHCI_CLE | OHCI_BLE)
.set OHCI_ALL_INTRS (OHCI_SO | OHCI_WDH | OHCI_SF | OHCI_RD | OHCI_UE | \
                        OHCI_FNO | OHCI_RHSC | OHCI_OC)
.set OHCI_NORMAL_INTRS (OHCI_WDH | OHCI_RD | OHCI_UE | OHCI_RHSC)
.endif

#.set OHCI_FSMPS(i) (((i-210)*6/7) << 16)
#.set OHCI_PERIODIC(i) ((i)*9/10)


	.set	OHCI_NO_INTRS,32
	.set	OHCI_HCCA_SIZE, 256
	.set	OHCI_HCCA_ALIGN, 256

	.set OHCI_PAGE_SIZEi,0x1000
	#.set OHCI_PAGE(x) ((x) &~ 0xfff)
	#.set OHCI_PAGE_OFFSET(x) ((x) & 0xfff)
	#.set OHCI_PAGE_MASK(x) ((x) & 0xfff)

# .set OHCI_ED_SIZE 16 #

	.set OHCI_ED_ALIGN,16
#
# set OHCI_TD_SIZE 16 
#
	.set	OHCI_TD_ALIGN,16

#
# set OHCI_ITD_SIZE 32 #
#
	.set OHCI_ITD_ALIGNi,32


.set OHCI_CC_NO_ERROR,,0
	.set	OHCI_CC_CRC,	1
.set OHCI_CC_BIT_STUFFING,2
.set OHCI_CC_DATA_TOGGLE_MISMATCH,3
.set OHCI_CC_STALL,4
.set OHCI_CC_DEVICE_NOT_RESPONDING,5
.set OHCI_CC_PID_CHECK_FAILURE,6
.set OHCI_CC_UNEXPECTED_PID,7
.set OHCI_CC_DATA_OVERRUN,8
.set OHCI_CC_DATA_UNDERRUN,9
.set OHCI_CC_BUFFER_OVERRUN,12
.set OHCI_CC_BUFFER_UNDERRUN,13
.set OHCI_CC_NOT_ACCESSED,,15

# Some delay needed when changing certain registers. #
	.set	OHCI_ENABLE_POWER_DELAY	,5
	.set	OHCI_READ_DESC_DELAY	,5

#
# PCI config registers 
#
	.set	USB_RELNUM		,0x60	# USB protocol revision 
	.set	PCI_USBREV_MASK		,0xff
	.set	PCI_USBREV_PRE_1_0	,0x00
	.set	USB_Specification_1_0	,0x10
	.set	USBREV_1_1		,0x11

#
#USB legacy keyboard/mouse control register
#
	.set	PCI_LEGKEY		,0xc0	# Legacy Support register 
	.set	PCI_LEGSUP_USBPIRQDEN	,0x2000	# USB PIRQ D Enable 
#
#base address register 
#ICH8 UHCI USB - D29:F0/F1/F2,D26:F0/F1
#
	.set USB_BASE_ADDR	,	0x20	# configuration base IO 

	.set PCI_INTERFACE_UHCI,0x00
	
#
# UHCI registers 
#
	.set	UHCI_CMD		,0x00
	.set  UHCI_CMD_RS		,0x0001
	.set  UHCI_CMD_HCRESET	,0x0002
	.set  UHCI_CMD_GRESET	,0x0004
	.set  UHCI_CMD_EGSM		,0x0008
	.set  UHCI_CMD_FGR		,0x0010
	.set  UHCI_CMD_SWDBG		,0x0020
	.set  UHCI_CMD_CF		,0x0040
	.set  UHCI_CMD_MAXP		,0x0080

	.set UHCI_STS		,0x02
	.set  UHCI_STS_USBINT	,0x0001
	.set  UHCI_STS_USBEI		,0x0002
	.set  UHCI_STS_RD		,0x0004
	.set  UHCI_STS_HSE		,0x0008
	.set  UHCI_STS_HCPE		,0x0010
	.set  UHCI_STS_HCH		,0x0020
	.set  UHCI_STS_ALLINTRS	,0x003f

	.set UHCI_INTR		,0x04
	.set  UHCI_INTR_TOCRCIE	,0x0001
	.set  UHCI_INTR_RIE		,0x0002
	.set  UHCI_INTR_IOCE		,0x0004
	.set  UHCI_INTR_SPIE		,0x0008

	.set UHCI_FRNUM		,0x06
	.set  UHCI_FRNUM_MASK	,0x03ff

	.set UHCI_FLBASEADDR	,0x08

	.set UHCI_SOF		,0x0c
	.set  UHCI_SOF_MASK	,	0x7f

	.set UHCI_PORTSC1      	,0x010
	.set UHCI_PORTSC2      	,0x012
	.set UHCI_PORTSC_CCS	,	0x0001
	.set UHCI_PORTSC_CSC	,	0x0002
	.set UHCI_PORTSC_PE	,	0x0004
	.set UHCI_PORTSC_POEDC	,0x0008
	.set UHCI_PORTSC_LS	,	0x0030
	.set UHCI_PORTSC_LS_SHIFT,	4
	.set UHCI_PORTSC_RD	,	0x0040
	.set UHCI_PORTSC_LSDA	,0x0100
	.set UHCI_PORTSC_PR	,	0x0200
	.set UHCI_PORTSC_OCI	,	0x0400
	.set UHCI_PORTSC_OCIC	,0x0800
	.set UHCI_PORTSC_SUSP	,0x1000
.if 0
.set URWMASK(x) \
  ((x) & (UHCI_PORTSC_SUSP | UHCI_PORTSC_PR | UHCI_PORTSC_RD | UHCI_PORTSC_PE))

.set UHCI_FRAMELIST_COUNT	,1024
.set UHCI_FRAMELIST_ALIGN	,4096

.set UHCI_TD_ALIGN		,16
.set UHCI_QH_ALIGN		,16

#typedef u_int32_t uhci_physaddr_t;
.set UHCI_PTR_T	,	0x00000001
.set UHCI_PTR_TD,		0x00000000
.set UHCI_PTR_QH,		0x00000002
.set UHCI_PTR_VF,		0x00000004

#
 * Wait this long after a QH has been removed.  This gives that HC a
 * chance to stop looking at it before it's recycled.
 
.set UHCI_QH_REMOVE_DELAY	,5

#
 * The Queue Heads and Transfer Descriptors are accessed
 * by both the CPU and the USB controller which run
 * concurrently.  This means that they have to be accessed
 * with great care.  As long as the data structures are
 * not linked into the controller's frame list they cannot
 * be accessed by it and anything goes.  As soon as a
 * TD is accessible by the controller it "owns" the td_status
 * field; it will not be written by the CPU.  Similarly
 * the controller "owns" the qh_elink field.
 

typedef struct {
	uhci_physaddr_t td_link;
	u_int32_t td_status;
.set UHCI_TD_GET_ACTLEN(s)	(((s) + 1) & 0x3ff)
.set UHCI_TD_ZERO_ACTLEN(t)	((t) | 0x3ff)
.set UHCI_TD_BITSTUFF	,0x00020000
.set UHCI_TD_CRCTO	,	0x00040000
.set UHCI_TD_NAK	,	0x00080000
.set UHCI_TD_BABBLE	,	0x00100000
.set UHCI_TD_DBUFFER	,	0x00200000
.set UHCI_TD_STALLED	,	0x00400000
.set UHCI_TD_ACTIVE	,	0x00800000
.set UHCI_TD_IOC	,	0x01000000
.set UHCI_TD_IOS	,	0x02000000
.set UHCI_TD_LS		,0x04000000
.set UHCI_TD_GET_ERRCNT(s)	(((s) >> 27) & 3)
.set UHCI_TD_SET_ERRCNT(n)	((n) << 27)
.set UHCI_TD_SPD		0x20000000
	u_int32_t td_token;
.set UHCI_TD_PID_IN	,	0x00000069
.set UHCI_TD_PID_OUT	,	0x000000e1
.set UHCI_TD_PID_SETUP	,0x0000002d
.set UHCI_TD_GET_PID(s)	((s) & 0xff)
.set UHCI_TD_SET_DEVADDR(a)	((a) << 8)
.set UHCI_TD_GET_DEVADDR(s)	(((s) >> 8) & 0x7f)
.set UHCI_TD_SET_ENDPT(e)	(((e)&0xf) << 15)
.set UHCI_TD_GET_ENDPT(s)	(((s) >> 15) & 0xf)
.set UHCI_TD_SET_DT(t)	((t) << 19)
.set UHCI_TD_GET_DT(s)	(((s) >> 19) & 1)
.set UHCI_TD_SET_MAXLEN(l)	(((l)-1) << 21)
.set UHCI_TD_GET_MAXLEN(s)	((((s) >> 21) + 1) & 0x7ff)
.set UHCI_TD_MAXLEN_MASK	0xffe00000
	u_int32_t td_buffer;
} uhci_td_t;

.set UHCI_TD_ERROR ,(UHCI_TD_BITSTUFF|UHCI_TD_CRCTO|UHCI_TD_BABBLE|UHCI_TD_DBUFFER|UHCI_TD_STALLED)

.set UHCI_TD_SETUP(len, endp, dev) (UHCI_TD_SET_MAXLEN(len) | \
     UHCI_TD_SET_ENDPT(endp) | UHCI_TD_SET_DEVADDR(dev) | UHCI_TD_PID_SETUP)
.set UHCI_TD_OUT(len, endp, dev, dt) (UHCI_TD_SET_MAXLEN(len) | \
     UHCI_TD_SET_ENDPT(endp) | UHCI_TD_SET_DEVADDR(dev) | \
     UHCI_TD_PID_OUT | UHCI_TD_SET_DT(dt))
.set UHCI_TD_IN(len, endp, dev, dt) (UHCI_TD_SET_MAXLEN(len) | \
     UHCI_TD_SET_ENDPT(endp) | UHCI_TD_SET_DEVADDR(dev) | UHCI_TD_PID_IN | \
     UHCI_TD_SET_DT(dt))

typedef struct {
	uhci_physaddr_t qh_hlink;
	uhci_physaddr_t qh_elink;
} uhci_qh_t;
.endif

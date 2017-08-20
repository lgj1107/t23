#include "stdio.h"
#include "m.h"
main()
{
	struct mem *p = (struct mem *)0;

	printf("\t.set\tPAGE_PML4E\t, 0x%x\n", &p->page_pml4e);
	printf("\t.set\tPAGE_PDPTE\t, 0x%x\n", &p->page_pdpte);
	printf("\t.set\tPAGE_APIC_PDE\t, 0x%x\n", &p->page_apic_pde);
	printf("\t.set\tPAGE_PDE\t, 0x%x\n", &p->page_pde);
	printf("\t.set\tPAGE_KNL_PDE\t, 0x%x\n", &p->page_knl_pde);
	printf("\t.set\tPAGE_VMX_PDE\t, 0x%x\n", &p->page_vmx_pde);
	printf("\t.set\tPAGE_TEMP_PDE\t, 0x%x\n", &p->page_temp_pde);
/*	printf("#define\tUDOT_SZ %d\n", sizeof(struct user)); */
}

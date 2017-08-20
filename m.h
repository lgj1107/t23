struct mem
{
	char  page_pml4e [0x1000];
	char  page_pdpte [0x1000];
	char  page_apic_pde [0x1000];
	char	page_pde [0x1000] ;	
	char	page_knl_pde [0x1000];
	char	page_vmx_pde [0x1000];
	char	page_temp_pde [0x1000];
}
struct k
{
}

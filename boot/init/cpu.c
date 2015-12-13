#include <stdint.h>
#include "memory.h"
#include "cpu.h"


static struct gdt_desc _gdt[MAX_DESCRIPTORS];
static struct gdtr _gdtr;

static void set_gdt_desc(uint32_t i, ,
			 uint8_t access, uint8_t grand) {
	if(i > MAX_DESCRIPTORS)
		return;
	memset((void*) &_gdt[i], 0, sizeof (gdt_descriptor));
	_gdt[i].base_low = base & 0xffff;
	_gdt[i].base_mid = (base >> 16) & 0xff;
	_gdt[i].base_high = (base >> 24) & 0xff;
	_gdt[i].limit = limit & 0xffff;
	_gdt[i].flags = access;
	_gdt[i].grand = (limit >> 16) & 0x0f;
	_gdt[i].grand |= grand & 0xf0;
}

/**
 * Install the gdt.
 * Set both code and data base address 0, limit 4GB.
 */
void install_gdt() {
	_gdtr.limit = sizeof(struct gdt_desc) * MAX_DESCRIPTORS;
	_gdtr.base = (uint32_t) _gdt;

	// null descriptor.
	set_gdt_desc(0, 0, 0, 0, 0);
	// code descriptor.
	set_gdt_desc(1, 0, 0xffffffff, 
}


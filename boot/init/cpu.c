#include <stdint.h>
#include "string.h"
#include "cpu.h"


static union gdt_desc _gdt[MAX_DESCRIPTORS];
static struct gdtr _gdtr;

static void set_gdt_desc(uint32_t i, uint64_t base, uint64_t limit,
			 uint8_t access, uint8_t grand) {
	if(i > MAX_DESCRIPTORS)
		return;
	memset((void*) &_gdt[i], 0, sizeof (union gdt_desc));
	_gdt[i].group.base_low = base & 0xffff;
	_gdt[i].group.base_mid = (base >> 16) & 0xff;
	_gdt[i].group.base_high = (base >> 24) & 0xff;
	_gdt[i].group.limit = limit & 0xffff;
	_gdt[i].group.flags = access;
	_gdt[i].group.grand = (limit >> 16) & 0x0f;
	_gdt[i].group.grand |= grand & 0xf0;
}

/**
 * Install the gdt.
 * Set both code and data base address 0, limit 4GB.
 */
void install_gdt() {
	_gdtr.limit = sizeof(union gdt_desc) * MAX_DESCRIPTORS;
	_gdtr.base = (uint32_t) _gdt;

	// null descriptor.
	set_gdt_desc(0, 0, 0, 0, 0);
	// code descriptor.
	set_gdt_desc(1, 0, 0xffffffff, 0b10011010, 0b11001111);
	// data descriptor.
	set_gdt_desc(2, 0, 0xffffffff, 0b10010010, 0b11001111);
	asm volatile ("lgdt _gdtr");
}


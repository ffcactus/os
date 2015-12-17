#include <stdint.h>
#include "string.h"
#include "terminal.h"
#include "cpu.h"

extern inline intptr_t memset(intptr_t s, uint8_t c, uint32_t n);

static union gdt_desc _gdt[MAX_DESCRIPTORS];
static struct idt_desc _idt[MAX_INTERRUPTS];
static struct gdtr _gdtr;
static struct idtr _idtr;

/**
 * Set a single GDT descriptor.
 */
static void set_gdt_desc(uint32_t i, uint64_t base, uint64_t limit,
			 uint8_t access, uint8_t grand) {
	if(i > MAX_DESCRIPTORS)
		return;
	memset((intptr_t) &_gdt[i], 0, sizeof (union gdt_desc));
	_gdt[i].group.base_low = base & 0xffff;
	_gdt[i].group.base_mid = (base >> 16) & 0xff;
	_gdt[i].group.base_high = (base >> 24) & 0xff;
	_gdt[i].group.limit = limit & 0xffff;
	_gdt[i].group.flags = access;
	_gdt[i].group.grand = (limit >> 16) & 0x0f;
	_gdt[i].group.grand |= grand & 0xf0;
}

/**
 * Install the GDT.
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
	__asm__ volatile ("lgdt _gdtr");
}

/**
 * The default interrupt handler.
 */
static void default_int_handler() {
	term_printf("\nUnhandled Exception!");
	for(;;);
}

/**
 * Set a single IDT descriptor.
 */
static void
set_idt_desc(uint32_t i, uint16_t flags, uint16_t selector, intptr_t irq) {
	if(i > MAX_INTERRUPTS)
		return;
	if(!irq)
		return;
	_idt[i].base_low = irq & 0xffff;
	_idt[i].base_high = (irq >> 16) & 0xffff;
	_idt[i].reserved =  0;
	_idt[i].selector = selector;
	_idt[i].flags = flags;
}

/**
 * Set the IDT.
 */
void install_idt() {
	uint32_t i;

	_idtr.limit = sizeof(struct idt_desc) * MAX_INTERRUPTS;
	_idtr.base = (uint32_t) &_idt;

	memset((intptr_t)_idtr.base, 0, _idtr.limit);

	for(i = 0; i < MAX_INTERRUPTS; i++)
		set_idt_desc(i, 0b01110001, 0x08,
			     (intptr_t) default_int_handler);
	__asm__ volatile ("lidt _idtr");
}

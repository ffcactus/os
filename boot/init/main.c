/**
 * This is the start point of the executable loaded by
 * bootloader.
 */
#include <stdint.h>
#include "terminal.h"
#include "cpu.h"

/**
 * Take it as main().
 */
void _start() {
	install_gdt();
	install_idt();
	term_init();
	term_printf("Loading kernel...\n");
	term_printf("This is %c.\nThis is dec %u,\t%d.\nThis is hex %h.\nThis is string %s.\n",
			'A',
			123,
			-321,
			0x1234abcd,
			"Hello World!");
	while(1);
}


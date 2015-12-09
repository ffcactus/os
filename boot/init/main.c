/**
 * This is the start point of the executable loaded by
 * bootloader.
 */
#include <stdint.h>
#include "terminal.h"

uint32_t ds = 0x1234;
/**
 * Take it as main().
 */
void _start() {
	uint32_t bss = 0x4321;
	bss += ds;
//	term_init();
//	term_printf("xxxx");
//	while(1);
}


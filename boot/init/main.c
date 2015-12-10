/**
 * This is the start point of the executable loaded by
 * bootloader.
 */
#include <stdint.h>
#include "terminal.h"

/**
 * Take it as main().
 */
void _start() {
	term_init();
	term_printf("Hello World!");
	while(1);
}


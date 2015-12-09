/**
 * This is the start point of the executable loaded by
 * bootloader.
 */
#include "terminal.h"

void kernel_main() {
	term_init();
	while(1);
}


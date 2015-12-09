/**
 * This file includes some utility to print something
 * during kernel initilization.
 */

#include <stddef.h>
#include <stdint.h>

#define COL	80
#define ROW	25
#define VGA_COLOR_TEXT_MAP_ADDR	0xb8000

//static uint8_t x, y;
//static int16_t * const map_start = (int16_t *)VGA_COLOR_TEXT_MAP_ADDR;

enum vga_color {
	COLOR_BLACK = 0,
	COLOR_BLUE = 1,
	COLOR_GREEN = 2,
	COLOR_CYAN = 3,
	COLOR_RED = 4,
	COLOR_MAGENTA = 5,
	COLOR_BROWN = 6,
	COLOR_LIGHT_GREY = 7,
	COLOR_DARK_GREY = 8,
	COLOR_LIGHT_BLUE = 9,
	COLOR_LIGHT_GREEN = 10,
	COLOR_LIGHT_CYAN = 11,
	COLOR_LIGHT_RED = 12,
	COLOR_LIGHT_MAGENTA = 13,
	COLOR_LIGHT_BROWN = 14,
	COLOR_WHITE = 15,
};


static inline uint16_t vga_char(char c, enum vga_color bg, enum vga_color fg) {
	uint16_t c16 = c;
	return c16 | ((fg | bg << 4) << 8);
}

void term_init(void) {
	uint16_t i;
	int16_t * const map_start = (int16_t *)VGA_COLOR_TEXT_MAP_ADDR;
	uint16_t c16 = vga_char(' ', COLOR_BLUE, COLOR_WHITE);
	for(i = 0; i < (COL * ROW); i++)
		map_start[i] = c16;
}

void term_printf(const char* s) {
	s = s;
}

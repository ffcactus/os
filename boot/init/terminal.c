/**
 * This file includes some utility to print something
 * during kernel initilization.
 */

#include <stddef.h>
#include <stdint.h>
#include "port.h"

#define COL	80
#define ROW	25
#define VGA_COLOR_TEXT_MAP_ADDR	0xb8000

static uint8_t x = 0, y = 0;
static int16_t * const map_start = (int16_t *)VGA_COLOR_TEXT_MAP_ADDR;

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

#define VGA_CTL_INDEX_REG	0x03d4
#define VGA_CTL_DATA_REG	0x03d5
#define CURSOR_LOCATION_H	0x0e
#define CURSOR_LOCATION_L	0x0f

static inline void update_cursor() {
	if(x == COL) {
		x = 0;
		y++;
		if(y == ROW) {
			//scroll();
		}
	}

	outb(VGA_CTL_INDEX_REG, CURSOR_LOCATION_L);
	outb(VGA_CTL_DATA_REG, x);
	outb(VGA_CTL_INDEX_REG, CURSOR_LOCATION_H);
	outb(VGA_CTL_DATA_REG, y);
}

static inline uint16_t vga_char(char c, enum vga_color bg, enum vga_color fg) {
	uint16_t c16 = c;
	return c16 | ((fg | bg << 4) << 8);
}

void term_init(void) {
	uint16_t i;
	int16_t * const map_start = (int16_t *)VGA_COLOR_TEXT_MAP_ADDR;
	uint16_t c16 = vga_char(' ', COLOR_BLUE, COLOR_WHITE);
	x = 0;
	y = 0;
	for(i = 0; i < (COL * ROW); i++)
		map_start[i] = c16;
}

void put_char(char c) {
	map_start[y * COL + x] = vga_char(c, COLOR_BLUE, COLOR_WHITE);
	x++;
	update_cursor();
}

void term_printf(const char* s) {
	while(*s != '\0') put_char(*s++);
}

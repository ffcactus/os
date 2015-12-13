/**
 * This file includes some utility to print something
 * during kernel initilization.
 */

#include <stddef.h>
#include <stdint.h>
#include <stdarg.h>
#include "terminal.h"
#include "port.h"

#define COL	80
#define ROW	25
#define VGA_COLOR_TEXT_MAP_ADDR	0xb8000

#define GET_VGA_COLOR(x, y) (((x) | (y) << 4) << 8)

static uint8_t x = 0, y = 0;
static int16_t * const map_start = (int16_t *)VGA_COLOR_TEXT_MAP_ADDR;
static uint16_t color = GET_VGA_COLOR(COLOR_WHITE, COLOR_BLACK);

#define VGA_CTL_INDEX_REG	0x03d4
#define VGA_CTL_DATA_REG	0x03d5
#define CURSOR_LOCATION_H	0x0e
#define CURSOR_LOCATION_L	0x0f

static inline uint16_t vga_char(char c) {
	uint16_t c16 = c;
	return c16 | color;
}

static inline void scroll(void) {
	size_t i;
	for(i = 0; i < COL * (ROW - 1); i++) {
		map_start[i] = map_start[i + COL];
	}
	while(i < (COL * ROW))
		map_start[i++] = vga_char(' ');
}

static inline void increase_x(uint8_t offset) {
	x += offset;
	if(x >= COL){
		x = 0;
		y++;
		if(y == ROW) {
			y--;
			scroll();
		}
	}
}

static inline void update_cursor() {
	uint16_t i = y * COL + x;
	outb(VGA_CTL_INDEX_REG, CURSOR_LOCATION_L);
	outb(VGA_CTL_DATA_REG, i & 0x00ff);
	outb(VGA_CTL_INDEX_REG, CURSOR_LOCATION_H);
	outb(VGA_CTL_DATA_REG, i >> 8);
}

static void put_char(char c) {
	switch(c) {
	case '\n':
		increase_x(COL);
		break;
	case '\t':
		increase_x(4);
		break;
	default:
		map_start[y * COL + x] = vga_char(c);
		increase_x(1);
	}
	update_cursor();
}

static inline void print_u(uint32_t x, uint32_t first, uint32_t scale, char* c)
{
	int32_t i;
	uint8_t head = 1;
	if(x == 0) {
		put_char('0');
	} else {
		while(first) {
			i = x / first;
			x = x % first;
			first = first / scale;
			if(head) {
				if(i != 0) {
					put_char(c[i]);
					head = 0;
				}
			} else {
				put_char(c[i]);
			}
		}
	}
}


static void print_uint32(uint32_t x)
{
	print_u(x, 1000000000, 10, "0123456789");
}

static void print_int32(int32_t x)
{
	if(x < 0) {
		put_char('-');
		x *= -1;
	}
	print_uint32((uint32_t) x);
}

static void print_hex(uint32_t x)
{
	put_char('0');
	put_char('x');
	print_u(x, 0x10000000, 0x10, "0123456789ABCDEF");
}

static void print_string(const char* s) {
	while(*s != '\0') put_char(*s++);
}

/**
 * The the terminal color.
 */
void term_color(enum vga_color fg, enum vga_color bg) {
	color = GET_VGA_COLOR(fg, bg);
}

/**
 * The initialization of the terminal.
 */
void term_init(void) {
	uint16_t i;
	int16_t * const map_start = (int16_t *)VGA_COLOR_TEXT_MAP_ADDR;
	uint16_t c16 = vga_char(' ');
	x = 0;
	y = 0;
	update_cursor();
	for(i = 0; i < (COL * ROW); i++)
		map_start[i] = c16;
}

/**
 * The simple implementation of printf.
 */
void term_printf(const char* fmt, ...)
{
	va_list ap;
	int32_t d;
	uint32_t u;
	uint32_t h;
	char c, *s;

	va_start(ap, fmt);
	while(*fmt != '\0') {
		if(*fmt == '%') {
			fmt++;
			if(*fmt == 'd') {
				d = va_arg(ap, int32_t);
				print_int32(d);
			} else if(*fmt == 'u') {
				u = va_arg(ap, uint32_t);
				print_uint32(u);
			} else if(*fmt == 'h') {
				h = va_arg(ap, uint32_t);
				print_hex(h);
			} else if(*fmt == 's') {
				s = va_arg(ap, char*);
				print_string(s);
			} else if(*fmt == 'c') {
				c = (char) va_arg(ap, int32_t);
				put_char(c);
			} else {
				put_char('?');
			}
		} else {
			put_char(*fmt);
		}
		fmt++;
	}
	va_end(ap);
}

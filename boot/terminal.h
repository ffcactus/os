#include "commom_header.h"
#include "string.h"

extern enum vga_color {
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

extern uint8_t make_color(enum vga_color fg, enum vga_color bg);

extern uint16_t make_vga_entry(char c, uint8_t color);

/**
 * Initialize the terminal. Clean all the content.
 */
extern void terminal_init();

/**
 * Set the current color, the color is combinded with frontground color and
 * background color.
 */
extern void terminal_set_color(enum vga_color);

/**
 * Put a char at a position.
 */
extern void terminal_putchar_at(char c, enum vga_color, size_t x, size_t y);

/**
 * Put a char at the current position.
 */
extern void terminal_putchar(char c);

/**
 * Put a string at a position.
 */
extern void terminal_putstr_at(char *str, enum vga_color, size_t x, size_t y);

/**
 * Put a string at the current position.
 */
extern void terminal_putstr(char *str, enum vga_color);



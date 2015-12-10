/**
 * The implementation of port operation.
 */
#ifndef PORT_H
#define PORT_H

#include <stdint.h>

extern inline uint8_t inb(uint16_t port) {
	uint8_t ret;
	asm volatile ("inb %w1, %0" : "=a"(ret) : "Nd"(port));
	return ret;
}

extern inline void outb(uint16_t port, uint8_t val) {
	asm volatile ("outb %b0, %w1" : : "a"(val), "Nd"(port));
}
#endif

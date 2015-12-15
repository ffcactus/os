#ifndef __STRING_H
#define __STRING_H

#include <stdint.h>
#include <stddef.h>

extern inline intptr_t *memset(intptr_t *s, uint8_t c, uint32_t n) {
	__asm__(
		"cld \n\t"
		"rep \n\t"
		"stosb \n\t"
		:: "a" (c), "D" (s), "c" (n)
		: "cx", "di"
		);
	return s;
}

extern inline intptr_t*
memcpy(intptr_t *dest, const intptr_t *src, uint32_t n) {
	__asm__ volatile (
		"cld \n\t"
		"rep \n\t"
		::"c" (n), "S" (src), "D" (dest)
		:"ecx", "esi", "edi"
		);
	return dest;
}

extern inline size_t strlen(const char* str) {
	size_t ret = 0;
	while(str[ret] != 0) ret++;
	return ret;
}

#endif

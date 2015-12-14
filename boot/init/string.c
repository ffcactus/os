#include <stdint.h>
#include <stddef.h>

void *memset(void *s, int c, size_t n) {
	void *ret = s;
	while(n--)
		*s++ = c;
	return ret;
}

void *memcpy(void *dest, const void *src, size_t n) {
	void *ret = dest;
	while(n--)
		*((uint8_t) dest++) = *((uint8_t)src++);
	return ret;
}


size_t strlen(const char* str) {
	size_t ret = 0;
	while(str[ret] != 0) ret++;
	return ret;
}





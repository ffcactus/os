#ifndef __STRING_H
#define __STRING_H

#include <stdint.h>
#include <stddef.h>

extern void *memcpy(void *dest, const void *src, size_t n);
extern void *memset(void *s, int c, size_t n);
extern size_t strlen(const char *s);

#endif

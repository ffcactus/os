#if !defined(__cplusplus)
#include <stdbool.h>
#endif
#include <stddef.h>
#include <stdint.h>


// Check if the compiler thinks we are targeting the wrong operating system.
#if defined(__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif

// Only work for the 32-bit x86 targets.
#if !defined(__i386__)
#error "This tutorial needs to be compiled with a x86-elf compiler"
#endif




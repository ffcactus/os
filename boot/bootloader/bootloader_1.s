/**
 * This is a bootloader which inside the cylinders 0, heads 0 and sectors 1. 
 * The size of it should be 512 bytes. It is used to loader the second
 * bootloader.
 */
.file "bootloader_1.s"
.code16
.section .text
.globl _start;
_start:
	cli
	hlt

# fill the rest of the space with 0, the last of the 2 bytes should contain
# the signature.
.space 512 - (_start - .) - 2, 0 
.word 0xAA55


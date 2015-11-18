/**
 * This is a bootloader which inside the cylinders 0, heads 0 and sectors 1. 
 * The size of it should be 512 bytes. It is used to loader the second
 * bootloader.
 */

#define MSG(x)  movw $x, %si; call message

.file "bootloader_1.s"

.section .data
log0: .asciz "First bootloader started."

.section .text
.code16
.globl _start;

.org 0x7c00
_start:
	jmp loader
loader:
	cli			# disable interrupt before we setup the stack.
	xorw %ax, %ax		# set the segment as the offset is start from address 0. 
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %ss
	movw $0x2000, %sp
	sti			# enable interrupt.
	mov log0, %si
	call message
	
	cli
	hlt

/**
 * Write the string pointed to by %si
 * Each char is wrote by using BIOS INT 0x10.
 * BIOS INT 0x10:
 * AH = 0x0e
 * AL = Character to write.
 * BH = Page Number (Should be 0)
 * BL = Foreground color (Graphics Modes Only)
 * When using the function, put the string address to si. The string
 * should end with 0.
 */
.type message, @function
message:
	movb $0xe, %ah
disp_loop:
	lodsb	# Loads a byte into the AL register
	orb %al, %al
	jz disp_done
	int $10
	jmp disp_loop
disp_done:
	ret


# fill the rest of the space with 0, the last of the 2 bytes should contain
# the signature.
.space 512 - (_start - .) - 2, 0 
.word 0xAA55




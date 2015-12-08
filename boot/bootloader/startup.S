/**
 * We've been loaded at 0x8000.
 */
	.file "startup.S"
	.text
	.code32
	.org 0x0000
.globl _start
_start:
	call clear_screen
	hlt	
	jmp .

clear_screen:
	movw $0x0000, %ax
	movw %ax, %es
	movl $0xb8000, %edi
	movw $2000, %cx
	movb $0x1f, %ah
	movb $' ', %al
	cld
	rep stosw
	ret

	

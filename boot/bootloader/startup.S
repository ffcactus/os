	.file "startup.S"
	.text
	.code16
	.org 0x0000
.globl _start
_start:
	movw $0x0800, %ax
	movw %ax, %ds
	movw %ax, %es
	movw $message, %si
1:
        movw $0x0001, %bx
        movb $0xe, %ah
        int $0x10
print:
        lodsb   # Loads a byte pointed by SI into AL.
        cmpb $0, %al
        jne 1b
	cli
	hlt       
message:
	.asciz "\r\nHello, This is the second BootLoader!!!\r\n"
	
	

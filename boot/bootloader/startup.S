.include "tools_16_header.S"


	.file "startup.S"
	.text
	.code16
	.org 0x0000
.globl _start
_start:
	cli
	movw $0x0800, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %gs
	movw %ax, %ss

	lgdt gdt_descriptor

	movl %cr0, %eax
	orl $1, %eax
	movl %eax, %cr0
	jmp $0x08, $protect_mode

# Includes some helpful functions.
.include "tools_16.S"
 
message:
	.asciz "Into protect mode.\r\n"

/**
 * The GDT table.
 */
gdt:
# null descriptor
	.quad 0
# code descriptor
	.word 0xffff 		# segment limit low
	.word 0			# base address low
	.byte 0			# base address middle
	.byte 0b10011010 	# access
	.byte 0b11001111 	# granularity
	.byte 0			# base address high
# data descriptor
	.word 0xffff    	# segment limit low
        .word 0         	# base address low
        .byte 0         	# base address middle
        .byte 0b10010010 	# access
        .byte 0b11001111 	# granularity
        .byte 0         	# base address high
gdt_end:
gdt_descriptor:
	.word gdt_end - gdt - 1
	.long 0x8000 + gdt


.code32
protect_mode:
	movw $0x0010, %ax 	# set data segments to data descriptor
	movw %ax, %ds
	movw %ax, %ss
	movw %ax, %es
	movl $0x90000, %esp
	cli
loop:
	jmp loop

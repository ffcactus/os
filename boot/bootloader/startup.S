/**
 * We've been loaded at 0x8000.
 */


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

	movb $0x0f, %ah
	int $0x10
	DUMP_REG
	call clear_screen_16
	PRINT $message
	lgdt gdt_descriptor

	movl %cr0, %eax
	orl $1, %eax
	movl %eax, %cr0
	jmp $0x08, $protect_mode

# Includes some helpful functions.
.include "tools_16.S"

clear_screen_16:
	movw $0xb800, %ax
	movw %ax, %es
	movw $0x0000, %di
	movw $2000, %cx
	movb $0x1f, %ah
	movb $' ', %al
	cld
	rep stosw
	movb $0x02, %ah
	movw $0x0000, %dx
	movb $0x00, %bh
	int $0x10
	ret
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
	movw %ax, %es
	movw %ax, %fs
	movw %ax, %gs
	movw %ax, %ss
	
	movl $0x90000, %eax
#	movl protect_mode, %eax
	movl %eax, %esp
	movl %eax, %ebp
#	call enable_a20
	call clear_screen
	
loop:
	jmp loop

enable_a20:
	in $0x64, %al
	test $2, %al
	jnz enable_a20
	movb $0xdd, %al
	out %al, $0x64
	ret

clear_screen:
	movw 0x0, %es
	movl $0xb8000, %edi
	movw $2000, %cx
	movb $0x01, %ah
	movb $'*', %al
	cld
	rep stosw
	ret

	

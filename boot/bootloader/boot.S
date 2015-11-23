/**
 * This is the first stage bootloader. It is used to loader the second
 * stage bootloader.
 */



# The address of this bootloader been loaded by BIOS
.equ BOOTLOADER_ADDR, 0x07c0

# The signature for bootloader.
.equ BOOT_MACHINE_SIGNATURE, 0xaa55

# The offset of the start of BPB (BIOS Parameter Block).
.equ BOOT_MACHINE_BPB_START, 0x03	

# The offset of the end of BPB (BIOS Parameter Block).
.equ BOOT_MACHINE_BPB_END, 0x5a

# The offset of the end of the partition table.
.equ BOOT_MACHINE_PART_END, 0x1fe



.macro scratch
mode:
	.byte 0
disk_address_packet:
sectors:
	.long 0
heads:
	.long 0
cylinders:
	.word 0
sector_start:
	.byte 0
head_start:
	.byte 0
cylinder_start:
	.word 0
.endm	

.macro PRINT str
	push %si
	push %ax
	push %bx
	movw $\str, %si
	call print
	pop %bx
	pop %ax
	pop %si
.endm

.macro DUMP begin, size
	movw $\begin, %si
	movw $\size, %cx
	call dump
.endm

/**
 * Entry point
 */
	.file "boot.S"
	.text
	.code16gcc
	.org 0x0000
.globl _start, start;
_start:
start:
# The offset 0x0000 must be a jump to the reset of code.
	jmp after_BPB
	nop
	. = _start + BOOT_MACHINE_BPB_START
	. = _start + 4
	scratch
	. = _start + BOOT_MACHINE_BPB_END
after_BPB:
	cli				# disable interrupt.
        movw $BOOTLOADER_ADDR, %ax	# set address expression
        movw %ax, %ds
        movw %ax, %es
	movw $BOOTLOADER_ADDR, %sp	# stack grows down to 0x0000
	PRINT message0
	DUMP hexdump, 15
done:
	jmp done
message0:
        .asciz  "Booting ...\r\n"
hexdump:
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08

/**
 * Write the string pointed to by %si
 * Each char is wrote by using BIOS INT 0x10.
 * BIOS INT 0x10:
 * AH = 0x0e
 * AL = Character to write.
 * BH = Page Number (Should be 0)
 * BL = Foreground color (Graphics Modes Only)
 * When using the function, put the string address to SI. The string
 * should end with 0.
 */
1:
	movw $0x0001, %bx
	movb $0xe, %ah
	int $0x10
print:
        lodsb   # Loads a byte pointed by SI into AL.
        cmpb $0, %al 
        jne 1b
        ret
	
/**
 * Dump a area of data.
 * Display 8 bytes of code each line. For every 10 line will wait for any key to continue.
 * SI = The start address
 * CX = The size of area to dump
 */
index:
.byte '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
.byte 'A', 'B', 'C', 'D', 'E', 'F'
enter_key:
.asciz "\r\n"
1:
	pop %dx
	ret
dump:
	push %dx		# DL = row counter, DH = column counter.
	movb $10, %dl
	movb $8, %dh
	cld
2:
	cmpw $0, %cx
	je 1b
	xorw %ax, %ax		# clean the AX at first.
	lodsb			# loads the byte pointed by SI into AL.
	push %ax		# because AH will be used, so we save AX.
	shr $4, %ax		# show first 4 bits.  
	movw $index, %di
	addw %ax, %di
	movb (%di), %al
	movb $0xe, %ah
	movw $0x0001, %bx	# Page number = 0, froeground color = 1.
	int $0x10
	pop %ax
	andw $0x000f, %ax 	# show last 4 bits.
	movw $index, %di
	addw %ax, %di
	movb (%di), %al
	movb $0xe, %ah
	movw $0x0001, %bx
	int $0x10
	movb $' ', %al		# display a space
	movb $0xe, %ah
	movw $0x0001, %bx
	int $0x10
	dec %cx
	dec %dh 
	jnz 2b
	PRINT enter_key	
	movb $8,%dh
	jmp 2b
	
	.fill 0x1fe - (. - _start) ,1,0
	.org _start + BOOT_MACHINE_PART_END
	.word BOOT_MACHINE_SIGNATURE

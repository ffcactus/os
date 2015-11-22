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
	movw $\str, %si
	call print
.endm

/**
 * Entry point
 */
	.file "boot.S"
	.text
	.code16
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
	#movw $BOOTLOADER_ADDR, %sp	# stack grows down to 0x0000
	PRINT message0
done:
	jmp done
message0:
        .ascii  "Booting ..."
        .byte 0

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
1:
	# movw $0x0001, %bx
	movb $0xe, %ah
	int $0x10
print:
        lodsb   # Loads a byte pointed by SI into the AL register
        cmpb $0, %al 
        jne 1b
        ret
	
	.fill 0x1fe - (. - _start) ,1,0
	.org _start + BOOT_MACHINE_PART_END
	.word BOOT_MACHINE_SIGNATURE

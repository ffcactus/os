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

/* The segment of disk buffer. The disk buffer MUST be 32K long and
   cannot straddle a 64K boundary.  */
.equ BOOT_MACHINE_BUFFER_SEG, 0x7000

.macro PRINT str
	pusha
	movw $\str, %si
	call print
	popa
.endm

.macro DUMP begin, size
	movw $\begin, %si
	movw $\size, %cx
	call dump
.endm

.macro RESET_DISK drive
	pusha
	movb $\drive, %dl
	movw 0x0, %ah
	call reset_disk
	popa
.endm

.macro READ_SECTORS drive, head, cylinder, sector, count, destination
	pusha
	movw $\destination, %ax
	movw %ax, %es
	xorw %bx, %bx
	movb $\drive, %dl
	movb $\head, %dh
	movb $\cylinder, %ch
	movb $\sector, %cl
	movb $\count, %al
	call read_sectors
	popa
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
disk_addr_packet:
	.byte 0x10		# (00h) size of packet
	.byte 0x00		# (01h) reserved
	.word 0x0001		# (02h) number of blocks to transfer
	.word 0x8000, 0x0000	# (04h) DWORD, transfer buffer
	.word 0x0010, 0x0000	# (08h) QWORD, starting absolute block number
	.word 0x0000, 0x0000	
				# (10h)
	. = _start + BOOT_MACHINE_BPB_END
after_BPB:
	cli				# disable interrupt.
        movw $BOOTLOADER_ADDR, %ax	# set address expression
        movw %ax, %ds
        movw %ax, %es
	# movw $BOOTLOADER_ADDR, %sp	# stack grows down to 0x0000
	PRINT message_booting

# We need make sure the BIOS supports the INT 13 extensions.
int13_ext_check:
	mov $0x41, %ah
	mov $0x55aa, %bx
	# DL should contain the drive value. But we'd better save it.
	push %dx
	int $0x13
        jc int13_ext_check_failed     
        cmpw $0xaa55, %bx
        jne int13_ext_check_failed
	andw $0x001, %cx	# if function 42h-44h,47h,48h are supported
	jz int13_ext_check_failed
	jmp read_cd_content

int13_ext_check_failed:
	PRINT message_no_int13_ext
	jmp loop

read_cd_content:

	# CHS mode : Cylinder-Head-Sector mode.
	# LBA mode : Logical Block Addressing mode.
	# When we use INT 13 extension, we use LBA mode in which
	# the device is taken as a single large device.

	PRINT message_loading_img
	pop %dx
	movw $disk_addr_packet, %si
	movb $0x42, %ah
	int $0x13
	jc error_read_sectors	
	
	DUMP 0x0400, 16
	jmp loop

error_read_sectors:
	PRINT message_sector_read_err
	jmp loop
loop:
	PRINT message_halt
	cli
	hlt
	jmp loop
message_booting:
        .asciz "Booting ...\r\n"
message_halt:
	.asciz "Boot Halt.\r\n"
message_no_int13_ext:
	.asciz "No INT13 extension. Boot failed.\r\n"
message_loading_img:
	.asciz "Loading OS image.\r\n"
message_sector_read_err:
	.asciz "Sector read error.\r\n"
hexdump:
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
 * Print the register's value.
 * 
print_reg:
		
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
	ret
dump:
	movb $10, %dl		# DL = row counter, DH = column counter.
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

/**
 * Reset the disk controller, let it go to the first sector.
 * BIOS INT 0x13
 * AH = 0x00
 * DL = Drive to reset.
 * Return:
 * AH = Status code.
 * CF = Clear if success, set if failure.
 */	
reset_disk:
	int $0x13
	jc reset_disk
	ret

/**
 * Read sectors into memory
 * BIOS INT 0x13
 * AH = 0x02
 * AL = Numbers of sectors to read.
 * CH = Low eight bits of cylinder number.
 * CL = Sector Number Bits 0-5. Bits 6-7 are for hard disks only.
 * DH = Head number.
 * DL = Drive number (Bit 7 set for hard disk)
 * ES:BX = Buffer to read sector to
 * Return
 * AH = Status code
 * AL = Number of sectors read
 * CF = Set if failure, cleaned if successful.
 */
read_sectors:
	int $0x13
	jc read_sectors
	ret

	.fill 0x1fe - (. - _start) ,1,0
	.org _start + BOOT_MACHINE_PART_END
	.word BOOT_MACHINE_SIGNATURE

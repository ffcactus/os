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
.equ BOOT_MACHINE_PART_END, 0x7fe

/* The segment of disk buffer. The disk buffer MUST be 32K long and
   cannot straddle a 64K boundary.  */
.equ BOOT_MACHINE_BUFFER_SEG, 0x7000

# Standard function entry
.macro ENTER
	pushw %bp
	movw %sp, %bp
.endm

# Standard function leave
.macro LEAVE
	movw %bp, %sp
	popw %bp
.endm

# Print a string.
.macro PRINT str
	pusha
	movw \str, %si
	call print
	popa
.endm

# Copy memory.
.macro MEM_COPY from, to, bytes
	pusha
	movw \from, %si
	movw \to, %di
	movw \bytes, %cx
	cld
	rep movsb	
	popa
.endm

.macro DUMP_REG
	movw %ax, ax
	movw %bx, bx
	movw %cx, cx
	movw %dx, dx
	movw %si, si
	movw %di, di
	DUMP $regs, $12
.endm

# Print a area of data in hex format.
.macro DUMP begin, size
	pusha
	movw \begin, %si
	movw \size, %cx
	call dump
	popa
.endm

# Backup the drive number.
.macro BACKUP_DRIVE_NUM
	movb %dl, drive
.endm

# Restore the drive number
.macro RESTORE_DRIVE_NUM
	movb drive, %dl
.endm

# Read sectors from CD.
.macro READ_CDROM sector_size, sector_offset0, sector_offset1, sector_offset2, sector_offset3
	pusha
        movw $disk_addr_packet, %si
	movw \sector_size, 0x02(%si)
	movw \sector_offset0, 0x08(%si)
	movw \sector_offset1, 0x0a(%si)
	movw \sector_offset2, 0x0c(%si)
	movw \sector_offset3, 0x0e(%si)	
        movb $0x42, %ah
        RESTORE_DRIVE_NUM
        int $0x13
	popa
.endm	

# In a directory entry, find file by name,
# and save the file head and length.
.macro SEARCH_FILE dir_entry, dir_size, name, file_entry, file_size
        pushw \file_size
        pushw \file_entry
        pushw \name
        pushw \dir_size
        pushw \dir_entry
        call search_file
        addw $10, %sp
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

# BIOS will pass drive number to DL, but DL will be changed
# by some BIOS interrupt call, so we need place to save it.
regs:
ax:
	.word 0
bx:	
	.word 0
cx:
	.word 0
dx:
	.word 0
si:
	.word 0
di:
	.word 0

tmp_word:
	.word 0
drive:
	.byte 0

# Disk address packet is a 'structure' that will be passed
# to the BIOS int13 extension call.
disk_addr_packet:
	.byte 0x10		# (00h) size of packet
	.byte 0x00		# (01h) reserved
	.word 0x0000		# (02h) number of blocks to transfer
	.word 0x8000, 0x0000	# (04h) DWORD, transfer buffer
	.word 0x0000, 0x0000	# (08h) QWORD, starting absolute block number
	.word 0x0000, 0x0000	
				# (10h)
entry_lba:
	.word 0x0000, 0x0000
entry_size:
	.word 0x0000, 0x0000	

	. = _start + BOOT_MACHINE_BPB_END
after_BPB:
	cli				# disable interrupt.
        movw $BOOTLOADER_ADDR, %ax	# set address expression
        movw %ax, %ds
        movw %ax, %es
	movw $BOOTLOADER_ADDR, %sp	# stack grows down to 0x0000
	BACKUP_DRIVE_NUM	
	sti

# We need make sure the BIOS supports the INT 13 extensions.
int13_ext_check:
	mov $0x41, %ah
	mov $0x55aa, %bx
	RESTORE_DRIVE_NUM
	int $0x13
        jc int13_ext_check_failed     
        cmpw $0xaa55, %bx
        jne int13_ext_check_failed
	andw $0x001, %cx	# if function 42h-44h,47h,48h are supported
	jz int13_ext_check_failed
	jmp read_cd_content

int13_ext_check_failed:
	PRINT $message_no_int13_ext
	jmp loop

read_cd_content:
	PRINT $message_loading_img

# Load the primary volume descriptor first, so that we can find
# root directory.
	READ_CDROM $0x0001, $0x0010, $0x0000, $0x0000, $0x0000
	jc error_read_sectors

	# 0x0400 + 0x9c (Directory entry for the root directory)
	# + 0x02 (Location of extent LBA)
	MEM_COPY $0x049e, $entry_lba, $4
	
	# 0x0400 + 0x9c + 0x0a
	MEM_COPY $0x04a6, $entry_size, $4
found_pri_vol_desc:
	
	# The data length should changed to number of blocks.
	movw $entry_lba, %si
	movw (%si), %bx
	READ_CDROM $1, %bx, $0x0000, $0x0000, $0x0000
	DUMP $0x0400, $16

	# Now our buffer should contain the root directory entries.
	SEARCH_FILE $0x0400, $0x0800, $my_dir, $entry_lba, $entry_lba  
	
	#DUMP $0x0400, $16
	jmp loop

error_read_sectors:
	PRINT $message_sector_read_err
	jmp loop
loop:
	PRINT $message_halt
	cli
	hlt
	jmp loop


message_halt:
	.asciz "Boot Halt.\r\n"
message_no_int13_ext:
	.asciz "No INT13 extension.\r\n"
message_loading_img:
	.asciz "Loading OS image.\r\n"
message_sector_read_err:
	.asciz "Read error.\r\n"
my_dir:
	.ascii "DDDD"
message_search_done:
	.asciz "Search done.\r\n"
message_found:
	.asciz "Found.\r\n"

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
	PRINT $enter_key
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
	PRINT $enter_key	
	movb $8,%dh
	jmp 2b

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

/**
 * search a file in a directory entry.
 * C prototype:
 * boolean search_file(
 *	uint_16 dir_entry,  	-- 4(%bp) 
 * 	uint_16 entry_size, 	-- 6(%bp)
 *	char* name,		-- 8(%bp)
 *	uint_16* file_entry,	-- 10(%bp)
 *	uint_16* file_size	-- 12(%bp)
 * );
 */
search_file:
	ENTER
	xorw %ax, %ax
	movw 4(%bp), %si
1:
	cmpb $0x00, (%si)
	je file_search_done
	# now the SI should point to the head of file entries.
	push %si
	# save next strade.
	movb (%si), %al
	# save file identifer length.
	xorw %cx, %cx
	movb 32(%si), %cl
	# to the offset of file identifer.	
	addw $33, %si
	movw 8(%bp), %di
	cld
	rep cmpsb
	je file_search_found
	pop %si
	addw %ax, %si
	jmp 1b
file_search_found:
	PRINT $message_found
file_search_done:
	PRINT $message_search_done
	LEAVE
	ret
	
	.fill BOOT_MACHINE_PART_END - (. - _start) ,1,0
	.org _start + BOOT_MACHINE_PART_END
	.word BOOT_MACHINE_SIGNATURE

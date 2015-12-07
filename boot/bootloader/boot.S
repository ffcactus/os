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

.include "tools_16_header.S"

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
	jmp end_loop

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

	# Now our buffer should contain the root directory entries.
	SEARCH_FILE $0x0400, $0x0800, $startup_file, $entry_lba, $entry_size  
	cmpb $1, %ah
	je load_startup
	jmp error_no_startup 
load_startup:
	movw $entry_lba, %si
	movw (%si), %bx
	READ_CDROM $1, %bx, $0x0000, $0x0000, $0x0000
	jc error_read_sectors
	jmp $0x0800, $0
	

error_read_sectors:
	PRINT $message_sector_read_err
	jmp end_loop
error_no_startup:
	PRINT $message_no_startup
	jmp end_loop
end_loop:
	cli
	hlt


message_halt:
	.asciz "Boot Halt.\r\n"
message_no_int13_ext:
	.asciz "No INT13 extension.\r\n"
message_loading_img:
	.asciz "Loading OS image.\r\n"
message_sector_read_err:
	.asciz "Sector Read error.\r\n"
message_no_startup:
	.asciz "Can't find startup.bin\r\n"
startup_file:
	.ascii "STARTUP.BIN;1"
message_search_done:
	.asciz "Search done.\r\n"
message_found:
	.asciz "Found.\r\n"

.include "tools_16.S"

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
 * search_file(
 *	uint_16 dir_entry,  	-- 4(%bp) 
 * 	uint_16 entry_size, 	-- 6(%bp)
 *	char* name,		-- 8(%bp)
 *	uint_16* file_entry,	-- 10(%bp)
 *	uint_16* file_size	-- 12(%bp)
 * );
 * Return:
 * AH = 1 = found; AH  = 0 = Not found.
 * AL = File flag.
 */
search_file:
	ENTER
	subw $3, %sp	# -2(%bp), temp_si
			# -3(%bp), temp_file_flag
	xorw %ax, %ax
	movw 4(%bp), %si
1:
	cmpb $0x00, (%si)
	je file_search_done
	# now the SI should point to the head of file entries.
	movw %si, -2(%bp)
	# save next strade.
	movb (%si), %al
	# save file identifer length.
	xorw %cx, %cx
	movb 32(%si), %cl
	# save file flag
	movb 25(%si), %bl
	movb %bl, -3(%bp)
	# to the offset of file identifer.	
	addw $33, %si
	movw 8(%bp), %di
	cld
	rep cmpsb
	je file_search_found
	movw -2(%bp), %si
	addw %ax, %si
	jmp 1b
file_search_found:
	# save file LBA
	movw -2(%bp), %si
	addw $2, %si
	movw 10(%bp), %di
	movw $4, %cx
	cld
	rep movsb	 
	
	# save file size.
	movw -2(%bp), %si
	addw $10, %si
	movw 12(%bp), %di
	movw $4, %cx
	cld
	rep movsb
	
	movb $1, %ah
	movb -3(%bp), %al	
	jmp file_search_leave
file_search_done:
	xorw %ax,%ax
file_search_leave:
	LEAVE
	ret
	
	.fill BOOT_MACHINE_PART_END - (. - _start) ,1,0
	.org _start + BOOT_MACHINE_PART_END
	.word BOOT_MACHINE_SIGNATURE

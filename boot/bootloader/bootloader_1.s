/**
 * This is a bootloader which inside the cylinders 0, heads 0 and sectors 1. 
 * The size of it should be 512 bytes. It is used to loader the second
 * bootloader.
 */

.macro MSG x
	movx $\x, %si
	call print 
.endm

.text
.code16
.globl _start;

# The boot sector of a floppy disk has a very specific layout,
# because the BISO requires access to certain data which it
# needs to find in the place it expects it to be. Also an operation
# system will need to access this data to determine how large
# the disk is, what file system it uses, what its valume label
# is and so on. We assume a floppy disk formatted with a FAT16
# file system here.

.org 0x0000
_start:
# The offset 0x0000 must be a jump to the reset of code.
	jmp loader
	nop
# From Offset 0x0003 to 0x002F is the BPB.
BPB:
oem:		.ascii "DevOS   "	# OEM String
sect_size:	.word 0x200		# bytes per sector
clust_size:	.byte 1			# sectors per cluster
res_sect:	.word 1			# size of reserved sectors
fat_cnt:	.byte 2			# number of FAT copies
root_size:	.word 224		# size of root directory
total_sect:	.word 2880		# total number of sectors if over 32 MB
media:		.byte 0xf0		# media descriptor
fat_size:	.word 9			# size of each FAT
track_sect:	.word 9			# sector per track
head_cnt:	.word 2			# number of read-write heads
hidden_sect:	.int 0			# number of hidden sectors
sect32:		.int 0			# number of sectors for over 32MB
boot_drive:	.byte 0			# the drive the boot sector came from
reserved:	.byte 0			# reserved
boot_sign:	.byte 0x29		# extended boot sector signature
vol_id:		.ascii "seri"		# disk serial
volume_label:	.ascii "MYVOLUME   "	# volume label
fs_type:	.ascii "FAT16   "	# file system type


# From Offset 0x0030 to 0x0061 is the EBPB.

# From Offset 0x0062 to 0x0510 is the boot code.
loader:
	cli			# disable interrupt before we setup the stack.
	movb %dl, boot_drive	# save what drive we booted from (0x0)
	movw %cs, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %ss
	movw $0x7c00, %sp	# stack grows down from offset 0x7c00 to 0x0000
	sti			# enable interrupt.

	movw $load_msg, %si
	call print
	
# Reset disk system.
# Jump to boot_failure on error.
	movb boot_drive, %dl
	xorw %ax, %ax
	int $0x13
	jc boot_failure

# End of loader.
	cli
	hlt

boot_failure:
	movw $disk_error, %si
	call print
	call reboot


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
.type print, @function
print:
	movb $0xe, %ah
disp_loop:
	lodsb	# Loads a byte into the AL register
	orb %al, %al
	jz disp_done
	int $10
	jmp disp_loop
disp_done:
	ret

/**
 * Reboot
 */
.type reboot, @function
reboot:
	movw $reboot_msg, %si
	call print
	xorw %ax, %ax
	int $0x16	# call BIOS to wait for key
	.byte 0xEA	# machine language to jump to FFFF:0000(reboot)
	.word 0x0000
	.word 0xffff

load_msg:
	.asciz "Loading OS..."
disk_error:
	.asciz "Disk error."
reboot_msg:
	.asciz "Press any key to reboot..."


# fill the rest of the space with 0, the last of the 2 bytes should contain
# the signature.
#end_of_boot:
#.space 324 
# From offset 0x0510 to 0x0511 is the boot signature
#magic_number:
.org 510
.byte 0x55, 0xaa


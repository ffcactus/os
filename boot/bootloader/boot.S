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
    movw \sector_size, %ax		# NOTE, sector on CD is 2Kb, BIOS sector is 512b.
    shlw $4, %ax
    movw %ax, 0x02(%si)
    movw \sector_offset0, 0x08(%si)
    movw \sector_offset1, 0x0a(%si)
    movw \sector_offset2, 0x0c(%si)
    movw \sector_offset3, 0x0e(%si)	
    movb $0x42, %ah
    RESTORE_DRIVE_NUM
    int $0x13
    popa
.endm	

.macro READ_CD_SECTOR sector_size, sector_offset0, sector_offset1, sector_offset2, sector_offset3
    pushw \sector_offset3
    pushw \sector_offset2
    pushw \sector_offset1
    pushw \sector_offset0
    pushw \sector_size
    call read_cd_sector
    addw $10, %sp
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
    .byte 0x10		        # (00h) size of packet
    .byte 0x00		        # (01h) reserved
    .word 0x0000		# (02h) number of blocks to transfer
    .word 0x8000, 0x0000	# (04h) DWORD, transfer buffer
    .word 0x0000, 0x0000	# (08h) QWORD, starting absolute block number
    .word 0x0000, 0x0000	
				# (10h)
entry_lba:
    .long 0x00000000
entry_size:
    .long 0x00000000	

    . = _start + BOOT_MACHINE_BPB_END

after_BPB:
    cli				# disable interrupt.
    movw $BOOTLOADER_ADDR, %ax	# set address expression
    movw %ax, %ds
    movw %ax, %es
    movw $BOOTLOADER_ADDR, %sp	# stack grows down to 0x0000
    movb %dl, drive		# save the drive.	
    sti

# We need make sure the BIOS supports the INT 13 extensions.
int13_ext_check:
    mov $0x41, %ah		# AH function number. 
    mov $0x55aa, %bx		# BX 0x55aa
    movb drive, %dl		# DL drive index.
    int $0x13
    jc int13_ext_check_failed   # CF Set on not present.
    cmpw $0xaa55, %bx		# BX 0xaa55 on present.
    jne int13_ext_check_failed
    andw $0x001, %cx		# if function 42h-44h,47h,48h are supported
    jz int13_ext_check_failed
    jmp read_cd_content
int13_ext_check_failed:
    PRINT $message_no_int13_ext
    jmp end_loop

# Now the BISO support read content from CD.
read_cd_content:
    PRINT $message_loading_img

# Load the primary volume descriptor first, so that we can find
# root directory.
    READ_CD_SECTOR $0x0001, $0x0010, $0x0000, $0x0000, $0x0000
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
    READ_CD_SECTOR $1, %bx, $0x0000, $0x0000, $0x0000
    # Now our buffer should contain the root directory entries.
    SEARCH_FILE $0x0400, $0x0800, $startup_file, $entry_lba, $entry_size  
    cmpb $1, %ah
    je load_startup
    jmp error_no_startup 
load_startup:
    PRINT $message_loading_startup
    movw $entry_size, %si
    movl (%si), %eax
    sarl $11, %eax
    movw %ax, (%si)		# NOTE: No more than 0xffff sectors!
    movw $entry_lba, %si
    movw (%si), %bx
    movw $entry_size, %si
    movw (%si), %ax
#   READ_CDROM %ax, %bx, $0x0000, $0x0000, $0x0000
#   DUMP_REG 
    READ_CD_SECTOR $2, %bx, $0x0000, $0x0000, $0x0000
    jc error_read_sectors
    cmpb $0, %ah
    jne error_read_sectors

# Prepare turn to protect mode.
    movb $0x00, %ah
    movb $0x03, %al
    int $0x10		        # Text mode, 16 colors, 80x25, 640x200.
	
    movb $0x02, %ah
    movb $0x00, %bh
    movw $0x0000, %dx
    int $0x10		        # Set cursor position to (0,0)

    cli			        # Turn off interrupt.
	
    lgdt gdt_descriptor	        # Load GDT descriptor.

    movl %cr0, %eax		# Open protect mode.
    orl $1, %eax
    movl %eax, %cr0

    movw $0x0010, %ax           # set data segments to data descriptor
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss
	
    movl $0x90000, %eax	        # set stack.
    movl %eax, %esp
    movl %eax, %ebp

    call enable_a20		# enable A20.

    jmp $0x08, $0x8000	        # jump to the target program.
	

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
message_loading_startup:
    .asciz "Loading startup.\r\n"
message_sector_read_err:
    .asciz "Sector Read error.\r\n"
message_no_startup:
    .asciz "Can't find startup.bin\r\n"
startup_file:
    .ascii "STARTUP.BIN;1"

.include "tools_16.S"

/**
 * Read sectors from CD. Assume the CD sector size is 2KB.
 *
 * C prototype :
 * read_cd_sector(
 *      uint_16 sector_size,    -- 4(%bp)
 *      uint_16 sector_offset0, -- 6(%bp)
 *      uint_16 sector_offset1, -- 8(%bp)
 *      uint_16 sector_offset2, -- 10(%bp)
 *      uint_16 sector_offset3  -- 12(%bp)
 * );
 * 
 * Each sectors on CD is 2KB. The sector_size means how many sector(2KB) 
 * you are going to read. The location that the data will be wrote to is
 * defined in disk_addr_packet. We already specify that the offset to 
 * 0x8000, so only 0xffff - 0x8000 = 0x7fff bytes left for us to write to.
 * so you can only read 15 sectors at a time.
 * If you are going to read the sector of offset 1, then sector_offset0
 * equals 1.
 * Return: CF Set On Error, Clear If No Error. AH return code.
 */
read_cd_sector:
    ENTER
    movw $disk_addr_packet, %si
    movw 4(%bp), %ax
    shlw $4, %ax
    movw %ax, 0x02(%si)
    movw 6(%bp), %ax
    movw %ax, 8(%si)
    movw 8(%bp), %ax
    movw %ax, 10(%si)
    movw 10(%bp), %ax
    movw %ax, 12(%si)
    movw 12(%bp), %ax
    movw %ax, 14(%si)
    movb $0x42, %ah               # INT 13h AH=42h: Extended Read Sectors From Drive
    movb drive, %dl
    int $0x13
    LEAVE
    ret

/**
 * Search a file in a directory entry.
 * C prototype:
 * search_file(
 *	uint_16 dir_entry,      -- 4(%bp) 
 * 	uint_16 entry_size,     -- 6(%bp)
 *	char* name,             -- 8(%bp)
 *	uint_16* file_entry,    -- 10(%bp)
 *	uint_16* file_size      -- 12(%bp)
 * );
 * Return:
 * AH = 1 = found; AH  = 0 = Not found.
 * AL = File flag.
 */
search_file:
    ENTER
    subw $3, %sp                # -2(%bp), temp_si
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

enable_a20:
    in $0x64, %al
    test $2, %al
    jnz enable_a20
    movb $0xdd, %al
    out %al, $0x64
    ret


/**
 * The GDT table.
 */
gdt:
# null descriptor
    .quad 0
# code descriptor
    .word 0xffff                # segment limit low
    .word 0                     # base address low
    .byte 0                     # base address middle
    .byte 0b10011010            # access
    .byte 0b11001111            # granularity
    .byte 0                     # base address high
# data descriptor
    .word 0xffff                # segment limit low
    .word 0                     # base address low
    .byte 0                     # base address middle
    .byte 0b10010010            # access
    .byte 0b11001111            # granularity
    .byte 0                     # base address high
gdt_end:
gdt_descriptor:
    .word gdt_end - gdt - 1
    .long 0x7c00 + gdt
	
	
    .fill BOOT_MACHINE_PART_END - (. - _start) ,1,0
    .org _start + BOOT_MACHINE_PART_END
    .word BOOT_MACHINE_SIGNATURE

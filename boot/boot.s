# Declare constants used for creating a multiboot header.
.set ALIGN, 1 << 0		# align loaded modules on page boundaries
.set MEMINFO, 1 << 1		# provide memory map
.set FLAGS, ALIGN | MEMINFO	# this is the Multiboot 'flag' field
.set MAGIC, 0x1BADB002		# 'magic number' for bootloader find the header
.set CHECKSUM, -(MAGIC + FLAGS) # checksum of above, to prove we are multiboot

# Declare a header as in the Multiboot Standard. We put this into a special
# section so we can force the header to be in the start of the final program.
# The bootloader will search for this magic sequence and recognize us as a 
# multiboot kernel.
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

# Currently the stack pointer register (esp) points at anything and using it
# may cause massive harm. Instead, we'll provide our own stack. We will 
# allocate room for a smal temporary stack by creating a symbol at the bottom
# of it, then allocating 16384 bytes for it, and finally creating a symbol at
# the top.
.section .bootstack, "aw", @nobits
stack_bottom:
.skip 16384	#16 KB
stack_top:

# The linker script specifies _start as the entry point to the kernel and the
# bootloader will jump to this position once the kernel has been loaded.
.section .text
.globl _start
.type _start, @function
_start:
	cli	# disable interrupt
	hlt	# stop the CPU until the next interrupt arrives
.hang:
	jmp .hang
# Set the size of the _start symbol to the current location '.' minus start.
# This is useful when debugging or when you implement call tracing.
.size _start, . - _start	

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

# Print a area of data in hex format.
.macro DUMP begin, size
        pusha
        movw \begin, %si
        movw \size, %cx
        call dump
        popa
.endm

.macro STOP
	cli
	hlt
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




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
        PRINT $enter_key
        ret
dump:
        movb $10, %dl           # DL = row counter, DH = column counter.
        movb $8, %dh
        cld
2:
        cmpw $0, %cx
        je 1b
        xorw %ax, %ax           # clean the AX at first.
        lodsb                   # loads the byte pointed by SI into AL.
        push %ax                # because AH will be used, so we save AX.
        shr $4, %ax             # show first 4 bits.
        movw $index, %di
        addw %ax, %di
        movb (%di), %al
        movb $0xe, %ah
        movw $0x0001, %bx       # Page number = 0, froeground color = 1.
        int $0x10
        pop %ax
        andw $0x000f, %ax       # show last 4 bits.
        movw $index, %di
        addw %ax, %di
        movb (%di), %al
        movb $0xe, %ah
        movw $0x0001, %bx
        int $0x10
        movb $' ', %al          # display a space
        movb $0xe, %ah
        movw $0x0001, %bx
        int $0x10
        dec %cx
        dec %dh
        jnz 2b
        PRINT $enter_key
        movb $8,%dh
        jmp 2b
	

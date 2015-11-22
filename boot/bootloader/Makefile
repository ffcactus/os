all:
	i686-elf-as -o boot.o boot.S
	i686-elf-ld --oformat=binary -Ttext=0x0 -o boot.bin boot.o

	dd status=noxfer conv=notrunc if=boot.bin of=floppy.flp
	qemu-system-i386 -fda floppy.flp




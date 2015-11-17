<<<<<<< HEAD
all:
	$(AS) -o bootloader_1.o bootloader_1.s

=======
AS=i686-elf-as
LD=i686-elf-ld
GCC=i686-elf-gcc

all:
	$(AS) -o bootloader_1.o bootloader_1.s
	mkdir -p iso
	$(GCC) -o iso/bootloader_1.img -ffreestanding -O2 -nostdlib bootloader_1.o -lgcc

test: all
	mkisofs -R -b bootloader_1.img -no-emul-boot -boot-load-size 1 -boot-info-table -o bootloader_1.iso iso
	qemu-system-i386 -cdrom bootloader_1.iso
>>>>>>> Save daily work.
clean:
	rm ./*.o


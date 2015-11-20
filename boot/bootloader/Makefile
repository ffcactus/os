AS=i686-elf-as
LD=i686-elf-ld
GCC=i686-elf-gcc

all:
	$(AS) -o bootloader_1.o bootloader_1.s
	$(GCC) -o bootloader_1.img -ffreestanding -O2 -nostdlib -Ttext=0x7c00 bootloader_1.o -lgcc

test: all
	rm -f floppy.img
	mkfs.vfat -C "floppy.img" 1440
	dd bs=512 if=bootloader_1.img of=floppy.img
	#cp -f bootloader_1.img iso/bootloader_1.img
	#mkisofs -R -b bootloader_1.img -no-emul-boot -boot-load-size 1 -boot-info-table -o bootloader_1.iso iso
	qemu-system-i386 -boot order=a -fda floppy.img
clean:
	rm -rf ./*.o *.img


all:
	i686-elf-as -o boot.o boot.S
	i686-elf-ld --oformat=binary -Ttext=0x0 -o boot.bin boot.o

fd: all
	dd status=noxfer conv=notrunc if=boot.bin of=floppy.flp
	qemu-system-i386 -fda floppy.flp

cd: all
	mkdir -p iso/boot
	cp boot.bin iso/boot/loader.sys
	mkisofs -R -J -c boot/bootcat \
		-b boot/loader.sys -no-emul-boot -boot-load-size 4 \
		-input-charset utf-8 \
		-o ./boot.iso ./iso
	qemu-system-i386 -cdrom boot.iso


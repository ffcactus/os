all:
	i686-elf-as -o boot.o boot.S
	i686-elf-ld --oformat=binary -Ttext=0x0 -o boot.bin boot.o
	i686-elf-as -o startup.o startup.S
	i686-elf-ld --oformat=binary -Ttext=0x0 -o startup.bin startup.o
	
# Make fd is for test only, our target media is CD.
fd: all
	dd status=noxfer conv=notrunc if=boot.bin of=floppy.flp
	qemu-system-i386 -fda floppy.flp

cd: all
	mkdir -p iso/BOOT
	cp boot.bin iso/BOOT/LOADER.SYS
	cp startup.bin iso/STARTUP.BIN
	mkisofs -R -J -c BOOT/BOOTCAT \
		-b BOOT/LOADER.SYS -no-emul-boot -boot-load-size 4 \
		-input-charset utf-8 \
		-o ./boot.iso ./iso
	hexdump -C boot.iso > boot.iso.dump
	qemu-system-i386 -cdrom boot.iso &

clean:
	@rm -rf iso boot.o boot.bin floppy.flp boot.iso


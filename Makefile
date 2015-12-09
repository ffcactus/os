AS=i686-elf-as
CC=i686-elf-gcc
LD=i686-elf-ld


all:
	cd boot; make all

clean:
	cd boot; make clean

cd: all
	mkdir -p target/iso/BOOT
	cp boot/bootloader/boot.bin target/iso/BOOT/LOADER.SYS
	cp boot/init/startup.bin target/iso/STARTUP.BIN
	mkisofs -R -J -c BOOT/BOOTCAT \
                -b BOOT/LOADER.SYS -no-emul-boot -boot-load-size 4 \
                -input-charset utf-8 \
                -o ./target/boot.iso ./target/iso
test: cd
	qemu-system-i386 -cdrom ./target/boot.iso &		

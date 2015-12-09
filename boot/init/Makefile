all:
	i686-elf-gcc -c main.c -o main.o -std=gnu99 -ffreestanding -Wall -Wextra
	i686-elf-gcc -c terminal.c -o terminal.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
	i686-elf-gcc -m32 -Ttext 0x8000 -o startup.elf -ffreestanding -O2 -nostdlib main.o terminal.o -lgcc
	objcopy -O binary startup.elf startup.bin
clean:
	@rm -rf main.o terminal.o startup.elf startup.bin


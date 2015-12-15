CC=i686-elf-gcc
#CFLAGS=-std=gnu99 -ffreestanding -finline-functions -Wall -Wextra
CFLAGS=-Wall -O -finline-functions -ffreestanding

.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

OBJS = main.o terminal.o cpu.o

all: $(OBJS)
	$(CC) -m32 -Ttext 0x8000 -o startup.elf -ffreestanding -O2 -nostdlib main.o terminal.o cpu.o -lgcc
	objcopy -O binary --set-section-flags .bss=alloc,load,contents startup.elf startup.bin
clean:
	@rm -rf *.o startup.elf startup.bin


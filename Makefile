CC=gcc
CFLAGS=-m64

ASM=nasm
AFLAGS=-f elf64

all:wynik

main.o: main.c
	$(CC) $(CFLAGS) -c main.c

func.o: func.asm
	$(ASM) $(AFLAGS) func.asm	

wynik: main.o func.o
	$(CC) $(CFLAGS) main.o func.o -o wynik `allegro-config --shared`
clean:
	rm *.o
	rm wynik

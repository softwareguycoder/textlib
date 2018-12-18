textlib.o: textlib.asm
	nasm -f elf -g -F stabs textlib.asm
clean:
	rm -f *.o

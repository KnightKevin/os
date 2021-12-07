run:
	@qemu-system-i386 -hda hd.img -serial null -parallel stdio
debug:
	@qemu-system-i386 -s -S -hda hd.img -serial null -parallel stdio &
	@sleep 1
	@gnome-terminal -e "gdb -q -x gdbinit"

build:
	@nasm -g -f elf32 mbr.asm -o mbr.o
	@ld -o mbr.symbol -melf_i386 -N mbr.o -Ttext 0x7c00
	@ld -o mbr.bin -melf_i386 -N mbr.o -Ttext 0x7c00 --oformat binary
	@dd if=mbr.bin of=hd.img bs=512 count=1 seek=0 conv=notrunc
clean:
	@rm -rf *.bin *.o *.symbol
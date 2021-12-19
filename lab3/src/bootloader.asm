%include "boot.inc"
org 0x7e00
[bits 16]
mov ax, 0xb800
mov gs, ax
mov ah, 0x03 ; 青色
mov ecx, bootloader_tag_end - bootloader_tag
xor ebx,ebx
mov esi, bootloader_tag

output_bootloader_tag:
    mov al, [esi]
    mov word[gs:bx],ax
    inc esi
    add ebx,2
    loop output_bootloader_tag


; 数据/代码段描述符的高32位基本规律应该是填0x_ _ c _ 9 8 _ _类似的数值，段界限只能最多填20位所以要在平坦模式下访问4GB内容，那就要将粒度设为4kb

; 空描述符
mov dword [GDT_START_ADDRESS+0x00], 0x00
mov dword [GDT_START_ADDRESS+0x04], 0x00

; 创建段描述符，这是一个数据段，对应0~4GB的线性地址空间
mov dword [GDT_START_ADDRESS+0x08],0x0000ffff
mov dword [GDT_START_ADDRESS+0x0c],0x00cf9200

; 建立保护模式下的堆栈段描述符
mov dword [GDT_START_ADDRESS+0x10],0x00000000 ; 基地址位0x00000000，界限0x0
mov dword [GDT_START_ADDRESS+0x14],0x00409600 ; 粒度为一个字节

; 建立保护模式下的显存描述符
mov dword [GDT_START_ADDRESS+0x18],0x80007fff ; 基地址为0x000B8000, 界限为0x07fff
mov dword [GDT_START_ADDRESS+0x1c],0x0040920b ; 粒度为字节

; 创建保护模式下平坦模式代码段描述符
mov dword [GDT_START_ADDRESS+0x20],0x0000ffff ; 基地址为0， 段界限为0xffff
mov dword [GDT_START_ADDRESS+0x24],0x00cf9800 ; 粒度为4kb, 代码段描述符

; 初始化描述符表寄存器GDTR
mov word [pgdt], 39 ; 描述符表的界限
lgdt [pgdt]

in al, 0x92 ; 南桥芯片内的端口
or al, 0000_0010B
out 0x92,al ; 打开A20

cli
mov eax,cr0
or eax,1
mov cr0,eax ; 设置PE位

; 以下进入保护模式
jmp dword CODE_SELECTOR:protect_mode_begin

; 16位的描述符段选择子:32偏移地址
; 清流水线并串行化处理器

[bits 32]
protect_mode_begin:

mov eax, DATA_SELECTOR
mov ds,eax
mov es,eax

mov eax,STACK_SELECTOR
mov ss, eax

mov eax, VIDEO_SELECTOR
mov gs,eax

mov ecx, protect_mode_tag_end - protect_mode_tag
mov ebx, 80*2
mov esi,protect_mode_tag
mov ah, 0x4
output_protect_mode_tag:
    mov al,[esi]
    mov word [gs:ebx],ax
    add ebx,2
    inc esi
    loop output_protect_mode_tag


jmp $

pgdt dw 0
     dd GDT_START_ADDRESS

bootloader_tag db 'run bootloader'
bootloader_tag_end:

protect_mode_tag db 'enter protect mode'
protect_mode_tag_end:
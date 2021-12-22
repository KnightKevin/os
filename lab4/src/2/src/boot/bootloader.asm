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

; 空描述符，因为按照定义要求，GDT的第一个描述符必须是空的
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

mov eax KERNEL_START_SECTOR
mov ebx KERNEL_START_ADDRESS
mov ecx KERNEL_SECTOR_COUNT

load_kernel:
    push eax
    push ebx
    call asm_read_hard_disk
    add esp, 8
    inc eax
    add ebx,512
    loop load_kernel

jmp CODE_SELECTOR:KERNEL_START_ADDRESS ; 跳转到kernel

jmp $

pgdt dw 0
     dd GDT_START_ADDRESS

bootloader_tag db 'run bootloader'
bootloader_tag_end:

protect_mode_tag db 'enter protect mode'
protect_mode_tag_end:

asm_read_hard_disk:
    push bp
    mov bp, sp
    
    push ax
    push bx
    push cx
    push dx

    mov ax, [bp + 2 * 3]


    mov dx,0x1f3
    out dx,al
    
    inc dx ; 0x1f4
    mov al,ah
    out dx,al

    xor ax, ax ; 开始设置 27~24位
    
    inc dx ; 0x1f5
    out dx,al

    inc dx ; 0x1f6
    mov al,ah
    and al,0x0f
    or al, 0xe0
    out dx, al

    mov dx,0x1f2
    mov al,1
    out dx,al

    mov dx,0x1f7
    mov al,0x20 ;读命令
    out dx,al

    .waits:
        in al, dx ; dx = 0x1f7
        and al,0x88
        cmp al,0x08
        jnz .waits

    ; 读取512字节到地址ds:bx中
    mov bx, [bp + 2 * 2]
    mov cx, 256 ; 每次读取一个字，2个字节
    mov dx, 0x1f0
    .readw
        in ax, dx
        mov [bx], ax
        add bx,2
        loop .readw
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp

    ret

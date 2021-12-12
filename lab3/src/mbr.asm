;%include "boot.inc"
org 0x7c00
[bits 16]
xor ax,ax ; eax = 0

mov ds,ax
mov ss,ax
mov es,ax
mov fs,ax
mov gs,ax

; 初始化栈指针
mov sp, 0x7c00

;mov ax, LOADER_START_SECTOR
;mov cx, LOADER_SECTOR_COUNT
;mov bx, LOADER_START_ADDRESS
mov ax,1 ; 逻辑扇区号第0~15位
mov cx,0 ; 逻辑扇区号的第16~31位
mov bx,0x7e00 ; bootloader的加载地址


load_bootloader:
    call asm_read_hard_disk ; 读取硬盘
    add sp,4
    inc ax
    cmp ax,5
    jle load_bootloader

    jmp 0x0000:0x7e00 ; 跳转到bootloader

jmp $ ;

; asm_read_hard_disk(memory, block)
; 加载逻辑扇区号为block的扇区到内存地址memory

asm_read_hard_disk:
    mov dx,0x1f3
    out dx,al
    
    inc dx ; 0x1f4
    mov al,ah
    out dx,al

    xor ax,ax
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
    mov cx, 256 ; 每次读取一个字，2个字节
    mov dx, 0x1f0
    .readw
        in ax, dx
        mov [bx], ax
        add bx,2
        loop .readw

    ret

times 510 - ($-$$) db 0
db 0x55, 0xaa

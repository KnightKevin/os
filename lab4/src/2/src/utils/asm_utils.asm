; 将整个项目用到的汇编函数放在这里面管理
[bits 32]

global asm_hello_word

asm_hello_word:
    push eax
    mov ah,0x03
    mov al, 'H'
    mov [gs:2*0], ax

    mov al, 'e'
    mov [gs:2*1], ax

    mov al, 'l'
    mov [gs:2*2], ax

    mov al, 'l'
    mov [gs:2*3], ax

    mov al, 'o'
    mov [gs:2*4], ax

    mov al, 'w'
    mov [gs:2*5], ax

    pop eax
    ret
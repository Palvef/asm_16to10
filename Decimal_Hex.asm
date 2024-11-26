DSEG SEGMENT
    ; 数据段定义
    num dw ?
    arr dw 10 dup(?)
    STRING1  DB  '[choose 0 (dec->hex) or 1 (hex->dec)]:$'
    STRING2  DB  '[input a hex number which must be four digits]:$'
    STRING3  DB  '[input a dec number which must be four digits]:$'
DSEG ENDS

CSEG SEGMENT

MAIN PROC FAR          ;主程序入口
    assume  cs:CSEG, ds:DSEG
;---------------------------------------------------------------------------

chose:
    mov ax, DSEG
    mov ds, ax
    mov es, ax

    lea dx, STRING1
    mov ah, 9
    int 21h         ; output string at ds:dx
    
    mov ah, 01h     ; 键盘输入并回显, AL=input char
    int 21h
    cmp al, 30h     ; 和 '0' 比较
    je  start2      ; 转到 10-16 进制入口
    cmp al, 31h     ; 和 '1' 比较
    je  start1      ; 转到 16-10 进制入口
    call change     ; 换行，重新选择
    jmp chose       ; 输入错误，让其重新输入

;---------------------------------------------------------------------------

start1:             ; 4 位 16 进制转 10 进制入口
    call change     ; 自动换行

    lea dx, STRING2
    mov ah, 9
    int 21h         ; output string at ds:dx

    mov num, 0
    mov cx, 4       ; 输入 4 位 16 进制数（这里没有处理少于或多于 4 位的情况）
L1:
    mov ah, 01h     ; 键盘输入并回显, AL=input char
    int 21h
    push cx         ; 保护 cx
    mov cl, 4
    shl num, cl     ; 输入的数以 10 进制的形式存到 num 中[逻辑左移 4 位]
    pop cx

    cmp al, 3ah     ; < 9 直接 al - '0' 扩展 -> num -> bx
    jb s1
    cmp al, 47h     ; 9 < G
    jb x1
    sub al, 20h     ; 小写的比大写的多减去 20h
x1:
    sub al, 7h
s1:
    sub al, 30h
    mov ah, 0
    add num, ax
    mov bx, num
    loop L1
solve1:
    call change     ; 自动换行
    call fun1        ; 调用主函数
    call change
    jmp chose
    call exit        ; 退出

;--------------------------------------------------------------------------

start2:             ; 4 位 10 进制转 16 进制入口
    call change     ; 自动换行

    lea dx, STRING3
    mov ah, 9
    int 21h         ; output string at ds:dx

    mov num, 0
    mov cx, 4       ; 输入 4 位 10 进制数（这里没有处理少于或多于 4 位的情况）
L2:
    mov ah, 01h     ; 键盘输入并回显, AL=input char
    int 21h
    push cx         ; 保护 cx
    push ax
    mov cx, 10d
    mov ax, num
    mul cx
    mov num, ax     ; 把 ax 给 num
    pop ax
    pop cx
s2:
    sub al, 30h     ; 输入转换为数字-'0'
    mov ah, 0
    add num, ax
    mov bx, num
    loop L2
    jmp solve2
solve2:
    call change     ; 自动换行
    call fun2        ; 调用主函数
    call change
    jmp chose
    call exit        ; 退出

;******************************************************************************;

MAIN ENDP

fun1 proc           ; 被除数放在 dx 中
    mov cx, 10000d    ; 把除数存放到 cx 中
    call dec_div

    mov cx, 1000d
    call dec_div

    mov cx, 100d
    call dec_div

    mov cx, 10d
    call dec_div

    mov cx, 1d
    call dec_div
    ret
fun1 endp

dec_div proc        ; 除法实现，除数为 cx 的值
    mov ax, bx
    mov dx, 0
    div cx          ; div 无符号:div src 16 位操作:商 ax=(dx, ax)/src, 余数 dx
    mov bx, dx
    mov dl, al

    add dl, 30h     ; 转换为 char 并显示
    mov ah, 02h
    int 21h
    ret
dec_div endp

fun2 proc           ; 被除数放在 dx 中
    mov cx, 1000h    ; 把除数存放到 cx 中
    call hex_div

    mov cx, 0100h
    call hex_div

    mov cx, 0010h
    call hex_div

    mov cx, 0001h
    call hex_div

    ret
fun2 endp

hex_div proc        ; 除法实现，除数为 cx 的值
    mov ax, bx
    mov dx, 0
    div cx          ; 除法, 商存在 ax，余数存在 dx
    mov bx, dx
    mov dl, al

    cmp dl, 10d     ; 和 10 比   >= 10
    jb show
    add dl, 7h      ; >= 10 的情况
show:
    add dl, 30h     ; 转换为 char 并显示
    mov ah, 02h
    int 21h
    ret
hex_div endp

; 回车换行
change proc
    push ax
    mov ah, 02h
    mov dl, 0ah
    int 21h
    mov ah, 02h
    mov dl, 0dh
    int 21h
    pop ax
    ret
change endp

; 退出
exit proc
    ; 按任意键退出
    mov ah, 1
    int 21h
    mov ax, 4c00h  ; 程序结束，返回到操作系统
    int 21h
exit endp


END MAIN

CSEG ENDS
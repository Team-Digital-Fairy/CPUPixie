section .text
org 0x100

jmp _entry ; call entry so I can main()

detect_v86:
	push bp
	mov bp, sp
	mov dx, v86_debug
	call printstr
	smsw ax
	and eax,1 ; CR0.PE = 1 = V86 MODE.
	pop bp
	ret


printstr:
	push bp ; save base pointer (aka entry)
	mov bp, sp ; BP is now SP.
	push ax
	xor ax,ax ; Clear AX
	mov ah, 9 ; calling 0x0900 on 0x21: STDOUT
	;mov dx,bx ; Pointer is on BX
	int 0x21
	pop ax
	pop bp ; Restore BP (aka leave)
	ret

_entry:
	mov dx, helloworld
	call printstr
	call detect_v86 ; Returning AX value that should contain V86 or not
	cmp ax,0 ; if it's not running on V86 mode (PE == 0)
	je _exit ; Exit
	mov dx, isv86 ; else, print
	call printstr 
_exit:
	ret

section .data
helloworld: db "Hello World from NASM?", 0x0A, 0x0D , '$'
isv86: db "This PC is running under V86 mode.", 0x0A, 0x0D, '$'
v86_debug: db "DBG: in detect_v86", 0x0A, 0x0D, '$'
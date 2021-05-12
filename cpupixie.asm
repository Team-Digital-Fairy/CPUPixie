section .text
org 0x100

jmp _entry ; call entry so I can main()

_addressToHex:
	push bp
	mov bp,sp

	xor ax, ax
	xor dx, dx
	mov di, [bp+6] ; string
	add di, 4
	mov ax, [bp+4] ; num
	mov bx, 16
	mov cx, 4
	
	processloop:
		div bx
		cmp dx, 9
		jg handleHex
		add dl, 0x30
		jmp loadByte
	
	handleHex:
		sub dl, 10
		add dl, 0x41
	
	loadByte:
		mov byte [di], dl
		dec di
		
		xor dx, dx
		dec cx
		jnz processloop

	mov ax, dx
	pop bp
	ret




detect_v86:
	push bp
	mov bp, sp
	mov dx, v86_debug
	call printstr
	smsw ax
	and eax,1 ; CR0.PE = 1 = V86 MODE.
	pop bp
	ret


check_386486:
	push bp
	mov bp, sp
	; try disabling and enable cache register in CR0
 	xor eax,eax
	mov eax,cr0 ; get current CR0.
	mov ebx,eax ; Copy CR0 for comparsion
	

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
	push teststr ; bp+6 is where string would be written into. 8088 does not have a ROM and RAM discrimination.
	mov ax, [_addressToHex]
	push ax
	call _addressToHex
	mov dx,teststr
	call printstr
	ret

section .data
helloworld: db "Hello World from NASM?", 0x0A, 0x0D , '$'
isv86: db "This PC is running under V86 mode.", 0x0A, 0x0D, '$'
v86_debug: db "DBG: in detect_v86", 0x0A, 0x0D, '$'
teststr: db ` XXXX\r\n$`


section .text
org 0x100

jmp _entry ; call entry so I can main()

;NCommander's itoa function.
_addressToHex:
	push bp
	mov bp,sp

	xor ax, ax
	xor dx, dx
	mov di, [bp+6] ; string
	add di, 4
	mov ax, [bp+4] ; num
	mov bx, 16 
	mov cx, [bp+8] ; loop counter
	
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
	and eax,1 ; CR0.PE = 1 = V86 MODE (and is in protected mode...).
	pop bp
	ret

check_acflag:
	push bp
	mov bp,sp
	
	pushfd
	pop eax ; read EFLAGS
	mov ecx, eax ; save EFLAGS to ECX
	
	push 8
	push teststr
	mov ax, [check_acflag_string1] ; bp+4
	push eax
	call _addressToHex
	mov dx,teststr
	call printstr
	
	
	xor eax, 0x40000 ; AC bit in EFLAGS
	push eax ; save modified EFLAGS
	popfd ; set eflags
	
	pushfd ; get new ELFLAGS
	pop eax ; store EFLAGS into EAX
	
	push 8
	push teststr
	mov ax, [check_acflag_string1] ; bp+4
	push eax
	call _addressToHex
	mov dx,teststr
	call printstr
	
	xor eax, ecx ; cannot toggle AC? it's 386.
	mov ax, 0
	jz _end_check_acflag ; it's 386.
	push ecx ; restore EFLAGS
	popfd
	mov ax, 1; it's 486.
_end_check_acflag:
	pop bp
	ret

_detect:
	push 		bp
	mov 		bp, sp
	pushf					; Push the original flags 
	pop 		ax			; 
	mov 		cx, ax			; 
	and 		ax, 0x0fff 		; clear bits 12-15 in FLAGS
	push 		ax			; save new FLAGS value on stack
	popf					; replace current FLAGS value
	pushf					; Get new flags
	pop 		ax			; AX <- flags
	and 		ax, 0xf000 		; if bits 12-15 are set, then
	cmp 		ax, 0xf000 		; 
	je 		_detected8088		; we only have an 8086/186 TODO: Further check 8088/186
	
	or		cx, 0xf000		; try to set bits 12-15
	push 		cx			; save new flags on the stack
	popf 					; replace current flags
	pushf 					; get new flags
	pop 		ax
	and 		ax, 0xf000  		; if bits 12-15 are clear
	jz 		_detected286		; if no bits set, processor is a 286
_detected8088:
	mov ax, 0 ; 0 = 8086/8088/186
	pop bp
	ret
_detected286:
	mov ax, 1 ; 1 = 286
	pop bp
	ret	

_do_386_and_up:
	; try disabling and enable cache register in CR0
 	xor eax,eax
	mov eax,cr0 ; get current CR0.
	mov ebx,eax ; Copy CR0 for comparsion
	and eax, 0xBFFF ; disable bit 30
	mov cr0,eax ; Disable caching. (MAYBE INCONSISTENT)
	nop
	nop
	nop
	nop ; Safeguard.
	mov eax,cr0 ; Read back.
	
	
	

	pop bp
	ret



printstr:
	push bp ; save base pointer (aka entry)
	mov bp, sp ; BP is now SP.
	push ax
	xor ax,ax ; Clear AX
	mov ah, 9 ; calling 0x0900 on 0x21: STDOUT
	int 0x21
	pop ax
	pop bp ; Restore BP (aka leave)
	ret

_detected_realmode:
	mov dx, v86_not_found
	call printstr
	jmp _exit

_8086_detected:
	mov dx, cpu8086
	call printstr
	jmp _exit
	
_entry:
		; are we in V86 mode?
		; if so, jump to _do_386_and_up
		; otherwise jump to _detect
		
	mov dx, helloworld
	call printstr
	
_detect_8086:
	mov bx, 0
	shr bx, _8086_detected ; !this trashes BX!
	; Interestingly, this turn into JMP rel8 in 8086. so...
	
	;call detect_v86 ; Returning AX value that should contain V86 or not
	;cmp ax,0 ; if it's not running on V86 mode (It's not in Protected Mode...)
	;je _detected_realmode ; Exit.
	;mov dx, isv86 ; else, print
	;call printstr
	call check_acflag
	cmp ax,0 ; if ax == 0
	je print386
	

print486:
	mov dx, cpu486
	call printstr
	jmp _exit
	
print386:
	mov dx, cpu386
	call printstr
	jmp _exit
	
_exit:
	mov ax, 0x4C00
	int 0x21
	nop

; Memo
	;push 4 ; Loop counter bp+8
	;push teststr ; bp+6 is where string would be written into. 8088 does not have a ROM and RAM discrimination.
	;mov ax, [_addressToHex] ; bp+4
	;push 0x7E0E
	;call _addressToHex
	;mov dx,teststr
	;call printstr


section .data
helloworld: db "Hello World from NASM?", 0x0A, 0x0D , '$'
isv86: db "This PC is running under V86 mode.", 0x0A, 0x0D, '$'
v86_debug: db "DBG: in detect_v86", 0x0A, 0x0D, '$'
v86_not_found: db `This PC is running under non-V86 mode\r\n$`
check_acflag_string1: db ` XXXXXXXX\r\n$`
teststr: db ` XXXX\r\n$`
cpu8086: db `This CPU is 8086/8088.\r\n$`
cpu386: db `this CPU is 386\r\n$`
cpu486: db `this CPU is 486\r\n$`

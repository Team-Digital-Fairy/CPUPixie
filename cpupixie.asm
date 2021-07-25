section .text
org 0x100

jmp _entry ; call entry so I can main()

;NCommander's itoa function.
_addressToHex:
	push bp
	mov bp,sp

	xor ax, ax
	xor dx, dx
	mov di, [bp+6] 		; string
	add di, 4
	mov ax, [bp+4] 		; num
	mov bx, 16 
	mov cx, [bp+8] 		; loop counter
	
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






check_acflag:
	push bp
	mov bp,sp
	
	pushfd
	pop eax 			; read EFLAGS
	mov ecx, eax 		; save EFLAGS to ECX
	
	push 8
	push teststr
	mov ax, [check_acflag_string1] 
						; bp+4
	push eax
	call _addressToHex
	mov dx,teststr
	call printstr
	
	
	xor eax, 0x40000 	; AC bit in EFLAGS
	push eax 			; save modified EFLAGS
	popfd 				; set eflags
	
	pushfd 				; get new ELFLAGS
	pop eax 			; store EFLAGS into EAX
	
	push 8
	push teststr
	mov ax, [check_acflag_string1] 
						; bp+4
	push eax
	call _addressToHex
	mov dx,teststr
	call printstr
	
	xor eax, ecx		; cannot toggle AC? it's 386.
	mov ax, 0
	jz _end_check_acflag; it's 386.
	push ecx 			; restore EFLAGS
	popfd
	mov ax, 1			; it's 486.
_end_check_acflag:
	pop bp
	ret


printstr:
	push ax
	xor ax,ax 			; Clear AX
	mov ah, 9 			; calling 0x0900 on 0x21: STDOUT
	int 0x21
	pop ax
	ret


	
_entry:
						; OLD COMMENTS
							; are we in V86 mode?
							; if so, jump to _do_386_and_up
							; otherwise jump to _detect
		
	mov dx, helloworld
	call printstr
	
_detect_8086:
	mov ax, _8086_detected 
	push ax				; Get the return address onto the stack for RETN
	mov bx, 0
	shr bx, (_8086c_detected - $)
						; !this trashes BX!
	; This assembles into C1 EB [imm8].
	; C1 is an invalid instruction (theoretically), but it is actually
	; an undocumented equivalent to RETN.
	; EB is a documented JMP rel8, so clones that don't copy the C1 functionality
	; Will fall into this.
	pop ax 				; The 8086 check passed, so we will get this off the stack
						; OLD COMMENTS
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

nop						; Nop slide, because we're jumping 3 bytes too early
nop						; Keep in mind, this MUST be within 255 bytes of shr bx, (_8086c_detected - $)
nop 					; Since that is a jmp [imm8]
nop
_8086c_detected:
	mov dx, cpu8086c	; Clones may not interpret C1 as RETN, we can take advantage of that
	call printstr 
	jmp _exit 

_8086_detected:
	mov dx, cpu8086		; The official 8086 interpretes C1 as RETN
	call printstr
	jmp _exit

print386:
	mov dx, cpu386
	call printstr
	jmp _exit
	
_exit:
	mov ax, 0x4C00
	int 0x21			; Return to DOS
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
helloworld: 	db "Hello World from NASM?", 0x0A, 0x0D , '$'
isv86: 			db "This PC is running under V86 mode.", 0x0A, 0x0D, '$'
v86_debug: 		db "DBG: in detect_v86", 0x0A, 0x0D, '$'
v86_not_found: 	db `This PC is running under non-V86 mode\r\n$`
check_acflag_string1: 
				db ` XXXXXXXX\r\n$`
teststr: 		db ` XXXX\r\n$`
cpu8086: 		db `This CPU is an 8088.\r\n$`
cpu8086c:		db `This CPU is an 8088 clone.\r\n$`
cpu386: 		db `this CPU is a 386.\r\n$`
cpu486: 		db `this CPU is a 486.\r\n$`

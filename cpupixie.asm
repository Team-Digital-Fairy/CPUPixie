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

; Print String function: 
; Push DX the pointer in DS
; call this.

printstr:
	push ax
	xor ax,ax 			; Clear AX
	mov ah, 9 			; calling 0x0900 on 0x21: STDOUT
	int 0x21
	pop ax
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

check_iopl:
	push bp
	mov bp,sp
	; Retrive flag
	xor ax,ax ; Clear AX
	pushf
	pop ax
	mov cx, ax ; Copy current FLAG to cx, just in case.
	; draw on screen
	push 4
	push teststr
	mov ax, [check_iopl]
	push ax
	call _addressToHex
	mov dx,teststr
	call printstr
	
	push cx
	popf
	
	pop bp
	ret


	
_entry:
	mov dx, helloworld
	call printstr
	mov dx, digifairy_intro
	call printstr
	mov dx,debug1
	call printstr
_detect_8086:
	mov ax, _8086_detected 
	push ax				; Get the return address onto the stack for RETN
	mov bx, 0
	shr bx, (_8086c_detected - $) ; !this trashes BX!
						; This assembles into C1 EB [imm8].
						; C1 is an invalid instruction (theoretically), but it is actually
						; an undocumented equivalent to RETN.
						; EB is a documented JMP rel8, so clones that don't copy the C1 functionality
						; Will fall into this.
	pop ax 				; The 8086 check passed, so we will get this off the stack

	; also this means that this is atleast 186.
	call check_iopl
	call check_acflag
	cmp ax,1 ; if ax == 1; that this is 486. because AC exists.
	je print486

print386:
	mov dx, cpu386
	call printstr
	jmp _exit

print486:
	mov dx, cpu486
	call printstr
	jmp _exit

_nop_slide_buffer:
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
; 80x25. add nesscery new lines if you wanna. print big text.
			   ;    0123456789012345678901234
helloworld: 	db `Hello World from NASM.\r\n$`
digifairy_intro:db `Made with <3\nfrom Team Digital Fairy!\r\n"Vespire:Our highness says\r\nthat you should have a great day!"\r\n$`
;isv86: 			db `This PC is running under V86 mode.\r\n$`
;v86_debug: 		db `DBG: in detect_v86\r\n$`
;v86_not_found: 	db `This PC is running under non-V86 mode\r\n$`
check_acflag_string1: 
				db ` XXXXXXXX\r\n$`
teststr: 		db ` XXXX\r\n$`
;teststr4: 		db ` XXXX\r\n$`
cpu8086: 		db `this CPU is an 8088.\r\n$`
cpu8086c:		db `this CPU is an 8088 clone.\r\n$`
cpu186:			db `this CPU is an 186.\r\n$`
cpu286:			db `this CPU is an 286.\r\n$`
cpu386: 		db `this CPU is an 386.\r\n$`
cpu486: 		db `this CPU is an 486.\r\n$`
cpu486_cpuid:	db `this CPU is an 486,  CPUID capable.\r\n$`

debug1:			db `debug: running 8086 detection\r\n$`
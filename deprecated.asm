; This file contains currently deprecated and unused subroutines
detect_v86:
	push bp
	mov bp, sp
	mov dx, v86_debug
	call printstr
	smsw ax
	and eax,1 ; CR0.PE = 1 = V86 MODE (and is in protected mode...).
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
    
_detected_realmode:
	mov dx, v86_not_found
	call printstr
	jmp _exit

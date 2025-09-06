org 0x0000
bits 16

start:
	jmp init

times 0x800 db 0 ;for testing, temporary

init:
	;test.. clears screen and prints a smiley face..
	mov ax, 0x1000
	mov es, ax
	mov ds, ax

	mov ah, 0x04
	int 0x21
	mov ah, 0x00
	mov si, welcome
	int 0x21

mainloop:
	;game loop
	call .pollinputs
	call .refreshscreen
	jmp mainloop

.pollinputs:
	;for now just checks for an escape key
	mov ah, 0x01
	int 0x16
	jz .continue
	cmp ah, 0x01;escape
	jz .escape
	.pollreturn:
		;clear key buffer
		mov ax, 0x00
		int 0x16
		ret
	.escape:
		;clears stack of return address
		mov ax, 0x00
		int 0x16
		pop ax
		push word 0x0050
		push word 0x0000
		retf ;jumps to kernel
	.continue:
		ret

		

.refreshscreen:
	ret

section .data

	welcome db 'Pong... if reading this means interrupt 21 successfully loaded pong into 0x1000:0x0000, and the kernel handed control over successfully', 0x0D, 0x0A, 0x00

org 0x0000
bits 16

%define WIDTH 320
%define HEIGHT 200

%define P1X 20
%define P2X 300

%define BORDERX1 10
%define BORDERX2 310
%define BORDERY1 10
%define BORDERY2 190

%define BGCOLOUR 0x16
%define BORDERCOLOUR 0x1E
%define PLAYERCOLOUR 0x28
%define NETCOLOUR 0x1B
%define BALLCOLOUR 0x0F


start:
	jmp init


init:
	;test.. clears screen and prints a smiley face..
	mov ax, 0x1000
	mov ds, ax
	;switch to 13h vga mode
	mov ax, 0x0013
	int 0x10

mainloop:
	;game loop
	call pollinputs
	call refreshscreen
	jmp mainloop

pollinputs:
	;for now just checks for an escape key
	mov ah, 0x01
	int 0x16
	jz .continue
	cmp ah, 0x01;escape
	jz .escape
	cmp ah, 0x11;W
	jz .w
	cmp ah, 0x1F;S
	jz .s
	cmp ah, 0x48;uparrow
	jz .up
	cmp ah, 0x50;downarrow
	jz .down
	.clearbuffer:
		mov ax, 0x00
		int 0x16
		ret
	.pollreturn:
		call .clearbuffer
		ret
	.escape:
		;clears stack of return address
		call .clearbuffer
		pop ax
		push word 0x0050
		push word 0x0000
		retf ;jumps to kernel
	.w:
		dec byte [p1position]
		jmp .pollreturn
	.s:
		inc byte [p1position]
		jmp .pollreturn
	.up:
		dec byte [p2position]
		jmp .pollreturn
	.down:	
		inc byte [p2position]
		jmp .pollreturn
	.continue:
		ret

refreshscreen:
	push es
	push ds
	mov ax, 0x9000
	mov es, ax
	call drawscene
	call .swapbuffers
	pop ds
	pop es
	ret

.swapbuffers:

	push ax
	push dx
	.wait_not_retrace:
		mov dx, 0x03DA
		in al, dx
		test al, 0x08
		jnz .wait_not_retrace
	.wait_retrace:
		mov dx, 0x03DA
		in al, dx
		test al, 0x08
		jz .wait_retrace
	pop dx
	pop ax
	mov ax, 0x9000
	mov ds, ax
	mov ax, 0xA000
	mov es, ax
	xor di, di
	xor si, si
	mov cx, 0xFA00
	rep movsb
	pop ds
	pop es
	ret

drawscene:

	call .drawbackground
	call .drawborder
	ret

.drawbackground:
	xor di, di
	mov al, BGCOLOUR
	mov cx, 0xFA00
	rep stosb
	ret
.drawborder:
	mov ax, BORDERX1
	mov bx, BORDERX2
	mov cx, 3
	mov dh, BORDERCOLOUR
	mov dl, BORDERY1
	call horizontalLine
	mov ax, BORDERX1
	mov bx, BORDERX2
	mov cx, 3
	mov dh, BORDERCOLOUR
	mov dl, BORDERY2
	call horizontalLine
	ret

;generic draw functions

;ax = start x, bx = end x, cx = thickness, dh = colour, dl = start y (top)
horizontalLine:
.hlineloop:
	xor di, di
	push ax
	push bx
	push dx
	xor ax, ax
	mov al, dl
	mov bx, WIDTH
	mul bx
	mov di, ax
	pop dx	
	pop bx
	pop ax
	add di, ax ; di stores dl * width + ax (starting offset)
	push cx
	push ax
	mov cx, bx
	sub cx, ax	;cx stores the number of bytes to write
	mov al, dh	;al the colour
	rep stosb
	pop ax
	pop cx
	
	inc dl
	dec cx
	cmp cx, 0x00
	jnz .hlineloop
	ret
	

;ah = start y, al = end y, bl = colour, cx = thickness, dx = start x (left)
verticalLine:
.vlineloop:
	;get starting di for column .. = ah * width + dx
	xor di, di
	push ax
	push bx
	mov bx, WIDTH
	mul bx
	add ax, dx
	mov di, ax
	pop bx
	pop ax
	push cx
	xor cx, cx
	sub al, ah
	mov cl, al
	.drawline:
		mov [es:di], byte bl
		add di, WIDTH
		dec cx
		cmp cx, 0x00
		jnz .drawline
	pop cx	
	inc ah
	dec cx
	cmp cx, 0x00
	jnz .vlineloop
	
dot:

section .data

	welcome db 'Pong... if reading this means interrupt 21 successfully loaded pong into 0x1000:0x0000, and the kernel handed control over successfully', 0x0D, 0x0A, 0x00
	p1position db 100
	p2position db 100
	

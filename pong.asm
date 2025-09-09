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
	;switch to 13h vga mode
	mov ax, 0x0013
	int 0x10
	mov ax, 0xA000
	mov es, ax	;es points to vga vram, will not be double buffering as pong is relatively static

	call drawbackground
	call drawplayers
	call drawscore
	call drawball

mainloop:
	call pollinputs
	call updategame
	call updatescreen
	call playaudio

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

updategame:
	;checks ball collisions and updates velocity/score
	call .hasballcollided
	cmp dh, 0x00
	jnz .updatevelocity	;updatevelocity and updatescore both return, as only one should be called
	cmp dl, 0x00
	jnz .updatescore
	ret

;function will store boolean (has the ball collided?) 
	; dh for reflective surfaces (1 for paddel, 2 for ceiling/floor)
	; and dl for the goal (1 for left point and 2 for right point)
.hasballcollided:
	;annoying function ill implement later
	ret

.updatevelocity:
	cmp dh, 0x01
	jz .horizontal
	cmp dh, 0x02
	jz .vertical
	ret
.horizontal:
	;flip most significant bit
	mov dl, byte [dx]
	xor dl, 10000000b
	mov [dx], dl
	ret
.vertical:
	mov dl, byte [dy]
	xor dl, 10000000b
	mov [dy], dl
	ret

.updatescore:
	mov [scorehaschanged], 0x01
	mov al, byte [score]
	cmp dl, 0x01
	jz .awardleft
	cmp dl, 0x02
	jz .awardright
	ret
.awardleft:
	add al, 0x10
	ret
.awardright:
	add al, 0x01
	ret

updatescreen:
	;updates the ball, then checks if anything else has moved before updating it
	call .updateball
	
	mov al, byte [p1hasmoved]
	cmp al, 0x00
	jnz .updatep1
	
	mov al, byte [p2hasmoved]
	cmp al, 0x00
	jnz .updatep2

	mov al, byte [scorehaschanged]
	cmp al, 0x00
	jnz .updatescoreboard

.updateball:
	ret
.updatep1:
	ret
.updatep2:
	ret
.updatescoreboard:
	ret

playaudio:
	;might implement audio in the future
	ret

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



section .data

	welcome db 'Pong... if reading this means interrupt 21 successfully loaded pong into 0x1000:0x0000, and the kernel handed control over successfully', 0x0D, 0x0A, 0x00
	p1position db 100
	p2position db 100
	p1hasmoved db 0x00
	p2hasmoved db 0x00

	score db 0x00	;one nibble per player, first to 15 wins
	scorehaschanged db 0x00
	
	;ball starts out as below, dy/dx = 1/5
	;
	;	     .....>
	;	x.....
	;
		
	dx 0x00000101   ;5px/f right, msb represents direction 0 ->, 1 <-
	dy 0x00000001   ;1px/f up, msb represents direction 0 /\, 1 \/
	


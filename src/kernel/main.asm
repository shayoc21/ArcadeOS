org 0x500
bits 16

%define ENDLINE 0x0D, 0x0A
%define ENDSTRING 0x00

start:
	jmp main

print:
	push ax
.printloop:
	lodsb
	or al, al
	jz .finished
	mov ah, 0x0E
	int 0x10
	jmp .printloop
.finished:
	pop ax
	ret

cls:
	pusha
	mov ax, 0x0003
	int 0x10
	popa
	ret

init:
	;prints a message to tell the user the kernel has loaded, then clears the screen
	pusha
	mov si, startup
	call print
	
	;bios stores an 18.2Hz tick counter at 0x0040:0x006C
	push es
	mov ax, 0x0040
	mov es, ax
	mov bx, [es:0x006C]
	mov cx, bx
	add cx, 18
	;wait routine will rest the pc for a second... completely cosmetic feature but makes boot more 'realistic'
	.wait:
		mov ax, [es:0x006C]
		cmp ax, cx
		jb .wait
	call cls
	mov si, loaded
	call print
	pop es
	popa
	ret

main:	
	mov ax, 0x0000
	mov es, ax
	mov ds, ax
	
	;dedicated stack segment 0x2000, well out of the way
	mov ax, 0x2000
	mov ss, ax
	mov sp, 0xFFFF
	
	call init

	

	hlt

;insurance, if halt fails then it will get stuck in this loop
.halt:
	jmp .halt

startup db 'Kernel Loaded... Booting into Operating System...', ENDLINE, ENDSTRING
loaded 	db 'Welcome!', ENDLINE, ENDSTRING


org 0x7C00
bits 16

%define ENDLINE 0x0D, 0x0A
%define ENDSTRING 0x00

start:
	jmp main
cls:
	pusha
	mov al, 0x03
	mov ah, 0x00
	int 0x10
	popa
	ret
print:
	pusha
	mov bx, 0
	mov ah, 0x0E
.loop:
	mov al, [message + bx]
	int 0x10
	inc bx
	cmp bx, length
	je .finished
	jmp .loop
.finished:
	popa
	ret
main:	
	mov ax, 0
	mov ds, ax
	mov es, ax

	mov ss, ax
	mov sp, 0x7C00
	
	call cls
	call print
.halt:
	jmp .halt 	; forbids CPU from starting up again, if it does then it will get stuck in this loop.

message db 'ArcadeOS, Developed by Shay OConnor <shaywoconnor@hotmail.com, github: shayoc21>', ENDLINE, ENDSTRING
length equ $ - message - 0x02

times 510-($-$$) db 0
dw 0xAA55

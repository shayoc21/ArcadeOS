org 0x0
bits 16

start:
	jmp main

;si = message offset
print:
	lodsb
	or al, al
	jz .finished
	mov ah, 0x0E
	int 0x10
	jmp print
.finished:
	ret

main:
	cli
	push cs
	pop ds
	mov si, message
	call print

	cli
	hlt
	jmp .halt

;insurance, if halt fails then it will get stuck in this loop
.halt:
	jmp .halt

message db "Kernel!", 0x0D, 0x0A, 0x00

org 0x500
bits 16

main:
	;prints a smiley face
	mov ah, 0x0E
	mov al, 0x01
	int 0x10

	hlt

;insurance, if halt fails then it will get stuck in this loop
.halt:
	jmp .halt


cls:
	pusha
	mov al, 0x03
	mov ah, 0x00
	int 0x10
	popa
	ret

;si = message offset
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

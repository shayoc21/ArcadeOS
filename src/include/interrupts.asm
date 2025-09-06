;like dos, i will have int 21 do most of the heavy lifting for programs.. depending on ah.

%include "./src/include/disk.asm"

section .text
int21_handler:

	cmp ah, 0x00
	je print_string
	cmp ah, 0x01
	je print_character
	cmp ah, 0x04
	je clear
	cmp ah, 0x10
	je load_program
i21done:
	iret

print_string:
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
	jmp i21done

print_character:
	push bx
	push ax
	;al stores character already
	mov ah, 0x0E
	int 0x10
	pop bx
	mov ah, bh
	pop bx
	jmp i21done

clear:
	pusha
	mov al, 0x03
	mov ah, 0x00
	int 0x10
	popa
	jmp i21done

;si points to the filename
load_program:
	mov ax, 0x07C0
	mov es, ax
	mov di, 0x0200
	call search_directory
	mov ax, 0x1000
	mov es, ax
	xor bx, bx
	call loadprogram ;calls the one with no underscore.. slightly different. will change names at some point
	jmp i21done

section .data
cluster dw 0x0000	

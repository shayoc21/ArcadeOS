start:
	jmp main


main:
	
.mainloop:
	
	;reads key presses
	
	call readkeypress	
	jnz .nokey	
	;scancode 0x01 is escape, when escape pressed i want to turn the pc off
	cmp ah, 0x01
	je .exit
	mov [keybuffer], ax
	
.nokey:
	jmp .mainloop

.exit:

	;turns the pc off
	;in qemu sending 0x2000 to 0x604 will turn pc off

	mov ax, 0x2000
	mov dx, 0x604
	out dx, ax

; takes no parameters, returns scancode in ah and ascii character in al, zf=0 if key pressed down
readkeypress:
	mov ah, 0x1
	int 0x16
	ret

;stores the most recent key press, lower 8 bits are the ascii, higher are the scancode
keybuffer dw 0	

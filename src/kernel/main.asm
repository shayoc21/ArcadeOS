org 0x500
bits 16


%define ENDLINE 0x0D, 0x0A
%define ENDSTRING 0x00

start:
	jmp main


%include "./src/include/print.asm"
%include "./src/include/interrupts.asm"

times 0x1000 db 0 ;test for the bootloader, can be removed but for now will stay 
		  ;had problems where the whole kernel wasn't loaded into 0x0050:0x0000.. this line was evidence of that

section .text
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
	call welcome
	pop es
	popa
	ret
welcome:
	call cls
	mov si, loaded
	call print
	ret

int20_handler:
	pusha
	call welcome
	popa
	iret

main:	
	mov ax, 0x0000
	mov es, ax
	mov ds, ax
	
	;
	;0x0000-0x04FF - BIOS junk / IVT
	;0x0500-0x3BFF - Main menu "Kernel"
	;0x3C00-0x7BFF - 16KB global stack ; technically unsafe as you could easily overwrite the bootloader in memory.. but you could do that anyway. will trust programs to not pop from an empty stack.
	;0x7C00-0x7DFF - Bootloader
	;0x7E00-0x99FF - Root directory
	;0x9A00-0xBDFF - FAT tables
	;0xBE00-0xFFFF - Empty
	;0x10000-END - Program memory
	mov ax, 0x03C0
	mov ss, ax
	mov sp, 0x4000

	;install int20, int21
	cli
	pusha
	mov ax, 0x0000
	mov es, ax
	mov di, 0x0080
	mov ax, int20_handler
	mov word [es:di], ax
	mov word [es:di + 0x2], 0x0000
	mov di, 0x0084
	mov ax, int21_handler
	mov word [es:di], ax
	mov word [es:di + 0x2], 0x0000
	popa
	sti
	
	call init
menu:
	mov si, prompt
	call print
	xor si, si ;zf = 1
.input:
	mov ah, 0x0
	int 0x16
	cmp ah, 0x01 ;escape
	je exit
	jmp game

exit:
	;acpi power off.. not stable so will halt just incase
	mov si, exiting
	call print
	hlt
.hltl:
	jmp .hltl

game:
	;for now im just going to load pong.bin into memory and hand over control.. will program a few more games in the future
	mov si, gamename
	call print
	mov si, gamename
	mov ah, 0x10
	int 0x21
	;jumps to program memory
	push word 0x1000
	push word 0x0000
	retf

section .data
	startup db 'Kernel Loaded... Booting into Operating System...', ENDLINE, ENDSTRING
	loaded 	db 'Welcome!', ENDLINE, ENDSTRING
	prompt 	db 'Press any key to play, Escape to exit', ENDLINE, ENDSTRING
	key	db 'key detected!!!', ENDLINE, ENDSTRING
	int20t	db 'int20test', ENDLINE, ENDSTRING
	gamename db 'PONG    BIN', ENDSTRING
	exiting db 'Exiting!', ENDLINE, ENDSTRING
	times 0x800 db 0




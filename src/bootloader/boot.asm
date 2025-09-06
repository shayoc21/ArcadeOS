org 0x7C00
bits 16

;fat12 header
			
			db 0xEB, 0x3C, 0x90

oem_identifier		db 'MSWIN4.1'		;8B
bytes_per_sector	dw 0x0200		;2B
sectors_per_cluster	db 0x01			;1B 
reserved_sectors	dw 0x0001		;2B
number_of_fats		db 0x02			;1B
directory_entries	dw 0x00E0		;2B
logical_sector_count	dw 0x0B40		;2B
media_descriptor_type	db 0xF0			;1B	0xF0 = 3.5inch floppy
sectors_per_fat		dw 0x0009		;2B
sectors_per_track	dw 0x0012		;2B
head_count		dw 0x0002		;2B
hidden_sector_count	dd 0			;4B
large_sector_count 	dd 0			;4B

; extended boot record
drive_number		db 0			;1B
			db 0			;1B
signature		db 0x1D			;1B
volume_id 		db 0x11,0x11,0x11,0x11	;4B	More or less arbitrary
volume_label		db 'ARCADEOS   '	;11B	Again, arbitrary so long as its padded with spaces
system_id		db 'FAT12   '		;8B

%define ENDLINE 0x0D, 0x0A
%define ENDSTRING 0x00

start:
	jmp main

%include "./src/include/print.asm"
%include "./src/include/disk.asm"

section .text
main:	
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov dl, al

	mov ss, ax
	mov sp, 0x7C00
	call cls

	;get size of root directory
	mov ax, 0x0020
	mul word [directory_entries]
	div word [bytes_per_sector]
	mov cx, ax
	
	mov al, [number_of_fats]
	mul word [sectors_per_fat]
	add ax, [reserved_sectors]
	push ax
	mov ax, 0x07C0
	mov es, ax
	pop ax
	mov bx, 0x0200
	;should read the root directory into 0x07C0:0x0200
	mov dl, [drive_number]
	mov si, root
	call print
	call read_disk

	mov si, fat 	
	call print
	mov si, kernelname
	mov di, bx
	call search_directory
	call loadfat
	
	mov ax, 0x0050
	mov es, ax
	xor bx, bx
	call loadprogram
	push 0x0050
	push 0x0000
	retf	;jump to kernel
	
root	db  'Loading Root', ENDLINE, ENDSTRING
fat 	db  'Loading FATs', ENDLINE, ENDSTRING
kernel	db  'Loading Kernel', ENDLINE, ENDSTRING

error 	db  'Error', ENDLINE, ENDSTRING

kernelname	 db 'KERNEL  BIN', 0x00
cluster dw 0x0000

times 510-($-$$) db 0
dw 0xAA55

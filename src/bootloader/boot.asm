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
cls:
	pusha
	mov al, 0x03
	mov ah, 0x00
	int 0x10
	popa
	ret

;ds:dx = message address, cx = length
print:
	push bx
	push ax
	push si
	
	mov si, dx
	mov bx, 0
	mov ah, 0x0E
.printloop:
	mov al, [si + bx]
	int 0x10
	inc bx
	cmp bx, cx
	je .printfinished
	jmp .printloop
.printfinished:
	pop si
	pop ax
	pop bx
	ret
main:	
	mov ax, 0
	mov ds, ax
	mov es, ax

	mov ss, ax
	mov sp, 0x7C00
	
	call cls
	push dx
	push cx
	mov dx, intro
	mov cx, introlength
	call print
	pop cx
	pop dx

	;read first 8 sectors into memory
	mov ax, 0x07E0
	mov es, ax
	mov bx, 0x0000
	mov cl, 0x08
	mov ax, 0x01
	mov dl, [drive_number]
	call read_disk

	;test... prints a message from outside the boot sector
	push dx
	push cx
	mov dx, 0x7FE8
	mov cx, 0x0A
	call print
	pop cx
	pop dx

	jmp .halt
.halt:
	jmp .halt 	; forbids CPU from starting up again, if it does then it will get stuck in this loop.

;ax = lba, returns head in dh, cx[0-5] = sector, cx[6-15] = cylinder
lba_chs_conversion:

	push ax
	push dx

	mov dx, 0
	div word [sectors_per_track]	;ax = lba/spt, dx = lba%spt
	inc dx				;dx = sector
	mov cx, dx			;stores sector [0-63] in first 6 bits of cx

	mov dx, 0			
	div word [head_count]		;ax = (lba/spt)/heads, dx = (lba/spt)%heads
	mov dh, dl
	mov ch, al
	shl ah, 6
	or cl, ah

	pop ax
	mov dl, al
	pop ax

	ret
;ax = lba, cl = number of sectors to read, dl = drive number, es:bx = address to store read data
read_disk:
	push dx
	push cx
	mov dx, readingfloppy
	mov cx, readinglength
	call print
	pop cx
	pop dx

	push di
	
	push cx
	call lba_chs_conversion
	pop ax				;pops cl into ax for int13h
	
	mov ah, 0x02
	mov di, 5

.retry:
	pusha
	stc
	int 0x13
	jnc .done
	
	mov dx, readingretry
	mov cx, retrylength
	call print
	
	mov ah, 0x1
	int 0x13
	
	mov ah, 0x0E
	int 0x10
	popa
	dec di
	jz .fail
	jmp .retry
.done:
	popa	
	push dx 
	push cx
	mov dx, readingsuccess
	mov cx, successlength
	call print
	pop cx
	pop dx
	pop di
	ret
.fail:
	push dx 
	push cx
	mov dx, readingfail
	mov cx, faillength
	call print
	pop cx
	pop dx
	pop di
	ret
	
intro		 db 'Welcome to this really cool operating system that shay oconnor wrote', ENDLINE, ENDSTRING
introlength	 equ $ - intro - 0x01

readingfloppy	 db 'Reading Floppy Disk...', ENDLINE, ENDSTRING
readinglength 	 equ $ - readingfloppy - 0x01

readingfail	 db '	...Error reading Floppy disk', ENDLINE, ENDSTRING
faillength	 equ $ - readingfail - 0x01

readingsuccess	 db '	...Successfully read from Floppy disk', ENDLINE, ENDSTRING
successlength	 equ $ - readingsuccess - 0x01

readingretry	 db '	...Retrying read from Floppy disk', ENDLINE, ENDSTRING
retrylength	 equ $ - readingretry - 0x01

times 510-($-$$) db 0
dw 0xAA55

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
	mov ax, 0
	mov ds, ax
	mov es, ax

	mov ss, ax
	mov sp, 0x7C00

	;get size of root directory
	mov ax, 0x0020
	mul word [directory_entries]
	div word [bytes_per_sector]
	mov cl, al
	
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
	call read_disk
	
	mov si, kernelname
	mov di, bx
	call search_directory
	
	mov ax, 0x0050
	mov es, ax
	mov bx, 0x0000	
	push bx
	
;now that the fat is loaded and i have the first cluster, I can load the kernel. this is the final step of my bootloader. loads into 0x0050:0x0000 
loadkernel:

	mov ax, [cluster]
	pop bx
	sub ax, 0x0002
	xor cx, cx
	mov cl, byte [sectors_per_cluster]
	mul cx
	call read_disk
	push bx

	mov ax, word [cluster]
	mov cx, ax
	mov dx, ax
	shr dx, 0x0001
	add cx, dx
	mov bx, 0x0200
	add bx, cx
	mov dx, word [bx]
	test ax, 0x0001
	jnz .odd

.even:
	and dx, 0000111111111111b
	jmp .done
.odd:
	shr dx, 0x0004

.done:
	mov word [cluster], dx
	cmp dx, 0x0FF0 ; end of file
	jb loadkernel

done:
	push word 0x0050
	push word 0x0000
	retf	;jump into kernel

;
;
;	fat root directory search:
;
;
;


;si points to file name, es:di points to root directory in memory, will load the fat after the bootloader and store the first cluster in "cluster"
search_directory:
	mov cx, [directory_entries]

.loop:
	push cx
	mov cx, 0x0B
	push di
	rep cmpsb
	pop di
	je .load_fat
	pop cx
	add di, 0x20	
	loop .loop
	jmp .failure

.failure:
	mov si, fatfail
	call print
	ret

.load_fat:
	mov dx, [di + 0x001A] ;di contains address of entry, byte 26 is the first cluster
	mov word [cluster], dx	
	xor ax, ax
	mov al, [number_of_fats]
	mul word [sectors_per_fat]
	mov cl, al
	mov ax, word [reserved_sectors]
	mov bx, 0x0200
	;reads the FAT to 0x07C0:0x0200
	call read_disk
	ret

;
;
;	disk reading
;
;


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
	mov si, readingfloppy
	call print

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
	
	mov si, readingretry
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
	mov si, readingsuccess
	call print
	pop di
	ret
.fail:
	mov si, readingfail
	call print
	pop di
	ret

;
;
;	data
;
;

readingfloppy	 db 'Reading disk', ENDLINE, ENDSTRING

readingfail	 db '...Error reading disk', ENDLINE, ENDSTRING

readingsuccess	 db '...Successfully read disk', ENDLINE, ENDSTRING

readingretry	 db '...Retrying read', ENDLINE, ENDSTRING

kernelname	 db 'KERNEL  BIN', 0x00

fatfail		 db '	...Failed to read file from FAT', ENDLINE, ENDSTRING

cluster	dw 0x0000

times 510-($-$$) db 0
dw 0xAA55

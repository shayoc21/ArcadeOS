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

main:	
	mov ax, 0
	mov ds, ax
	mov es, ax

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
	sub ax, 0x0002
	xor cx, cx
	mov cl, byte [sectors_per_cluster]
	mul cx
	add ax, 0x21
	call read_disk
	
	mov ax, [cluster]
	mov cx, ax
	shr ax, 1
	add cx, ax
	mov si, cx
	push ds
	mov ax, 0x07C0
	mov ds, ax
	mov ax, [ds:si + 0x200]
	pop ds
	
	test word [cluster], 0x0001
	jnz .odd_cluster

.even_cluster:
	and ax, 0x0FFF
	jmp .done
.odd_cluster:
	shr ax, 0x04

.done:
	mov [cluster], ax
	cmp ax, 0x0FF8
	jae done
	
	mov ax, [sectors_per_cluster]
	mov cx, 0x200
	mul cx
	mov cx, 0x10
	div cx
	mov bx, es
	add bx, ax
	mov es, bx
	xor bx, bx
	
	jmp loadkernel


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
	push si
	rep cmpsb
	pop si
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
	mov dx, [es:di + 0x1A]
	mov word [cluster], dx	
	xor ax, ax
	mov al, [number_of_fats]
	mul word [sectors_per_fat]
	mov cl, al
	mov ax, word [reserved_sectors]
	mov bx, 0x0200
	;reads the FAT to 0x07C0:0x0200
	call read_disk
	pop cx
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
	
	push ax
	push bx
	push cx
	push dx
	push di
	
	mov si, readingfloppy
	call print

	push cx
	call lba_chs_conversion
	pop ax				;pops cl into ax for int13h
	
	mov ah, 0x02
	mov di, 0x03

.retry:
	pusha
	stc
	int 0x13
	jnc .done

	mov si, readingretry
	call print

	mov al, ah      
	mov ah, 0x0E
	int 0x10 

	popa
	
	pusha
	mov ah, 0x0
	stc
	int 13h
	jc .fail
	popa
	
	dec di
	jz .fail
	jmp .retry
.done:
	popa

	pop di
	pop dx
	pop cx
	pop bx
	pop ax

	mov si, readingsuccess
	call print
	ret
.fail:
	mov si, readingfail
	call print
	hlt

;
;
;	data
;
;

readingfloppy	 db 'Reading', ENDLINE, ENDSTRING

readingfail	 db 'Error r', ENDLINE, ENDSTRING

readingsuccess	 db 'Successfully r', ENDLINE, ENDSTRING

readingretry	 db 'Retrying r', ENDLINE, ENDSTRING

kernelname	 db 'KERNEL  BIN', 0x00

fatfail		 db 'Failed to r', ENDLINE, ENDSTRING

cluster	dw 0x0000

times 510-($-$$) db 0
dw 0xAA55

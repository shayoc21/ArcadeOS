;get first cluster, si points to filename, es:di points to root directory
search_directory:
	mov cx, [0x7C11] ;[0x7C11] = root directory entries
.loop:
	push cx
	mov cx, 0x0B
	push di
	push si
	rep cmpsb
	pop si
	pop di
	je .found
	pop cx
	add di, 0x20
	loop .loop
.found:
	;loads first cluster into [cluster]
	mov dx, [es:di + 0x1A]
	mov word [cluster], dx
	pop cx
	ret

;just loads the fat into 0x09A0:0x0600
loadfat:
	xor ax, ax
	mov al, [0x7C10] 	;number of fats
	mul word [0x7C16] 	;sectors per fat
	mov cl, al
	mov ax, word [0x7C0E] 	;reserved sectors
	push ax
	mov ax, 0x09A0
	mov es, ax
	mov bx, 0x0600
	pop ax
	call read_disk
	ret

;loads the program pointed to by [cluster], es:bx points to the destination address
loadprogram:
	push bx
.loadcluster:
	mov ax, [cluster]
	sub ax, 0x0002
	xor cx, cx
	mov cl, byte [0x7C0D] ;[0x7C0D] = number of sectors per cluster
	mul cx
	add ax, 0x21
	call read_disk
	
	mov ax, [cluster]
	mov cx, ax
	shr ax, 1
	add cx, ax
	mov si, cx
	push ds
	mov ax, 0x09A0
	mov ds, ax
	mov ax, [ds:si + 0x0600]
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
	jae .programloaded
	
	mov al, byte [0x7C0D]
	mov cx, 0x200
	mul cx
	mov cx, 0x10
	div cx
	mov bx, es
	add bx, ax
	mov es, bx
	xor bx, bx
	jmp .loadcluster
	
.programloaded:
	pop bx
	ret

lba_chs_conversion:

	push ax
	push dx

	mov dx, 0
	div word [0x7C18]	;ax = lba/spt, dx = lba%spt
	inc dx				;dx = sector
	mov cx, dx			;stores sector [0-63] in first 6 bits of cx

	mov dx, 0			
	div word [0x7C1A]		;ax = (lba/spt)/heads, dx = (lba/spt)%heads
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

	mov al, ah      
	mov ah, 0x0E
	int 0x10 

	popa
	
	pusha
	mov ah, 0x0
	stc
	int 0x13
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

	ret
.fail:
	;prints error message.. (smiley face)
	mov ah, 0x0E
	mov al, 0x01
	int 0x10
	ret



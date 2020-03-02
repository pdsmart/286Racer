	PAGE	60,80
	TITLE 	Routines to do link communications.

_TEXT	SEGMENT BYTE PUBLIC 'CODE'
_TEXT	ENDS
CONST	SEGMENT	WORD PUBLIC 'CONST'
CONST	ENDS
_BSS	SEGMENT	WORD PUBLIC 'BSS'
_BSS	ENDS
_DATA	SEGMENT WORD PUBLIC 'DATA'
_DATA	ENDS

DGROUP	GROUP	CONST,	_BSS,	_DATA
	ASSUME	CS: _TEXT, DS: DGROUP, SS: DGROUP, ES:DGROUP

_DATA	SEGMENT
_DATA	ENDS	

_TEXT	SEGMENT
	
	PUBLIC	_readbyte
_readbyte PROC	NEAR
	mov	dx,0211h
rdbyte1:in	al,dx
	test	al,00001000b
	jnz	rdbyte1
	dec	dx
	in	al,dx
	xor	ah,ah
	ret
_readbyte ENDP

	PUBLIC	_readword
_readword PROC	NEAR
	mov	dx,0211h
rdword1:in	al,dx
	test	al,00001000b
	jnz	rdword1
	dec	dx
	in	al,dx
	xchg	al,ah
	inc	dx
rdword2:in	al,dx
	test	al,00001000b
	jnz	rdword2
	dec	dx
	in	al,dx
	xchg	al,ah
	ret
_readword ENDP

	PUBLIC	_readstat
_readstat PROC	NEAR
	push	bp
	mov	bp,sp
	mov	dx,0211h
	in	al,dx
	test	al,00001000b
	mov	al,1
	jz	rds
	mov	al,0
rds:	xor	ah,ah
	mov	sp,bp
	pop	bp
	ret
_readstat ENDP

	PUBLIC	_writebyte
_writebyte PROC NEAR
	push	bp
	mov	bp,sp
	mov	dx,0211h
wrbyte1:in	al,dx
	test	al,00000001b
	jz	wrbyte1
	mov	ax,[bp+4]
	dec	dx
	out	dx,al
	pop	bp
	ret
_writebyte ENDP

	PUBLIC	_writeword
_writeword PROC	NEAR
	push	bp
	mov	bp,sp
	mov	dx,0211h
wrword1:in	al,dx
	test	al,00000001b
	jz	wrword1
	dec	dx
	mov	ax,[bp+4]
	out	dx,al
	inc	dx
wrword2:in	al,dx
	test	al,00000001b
	jz	wrword2
	dec	dx
	mov	ax,[bp+4]
	xchg	al,ah
	out	dx,al
	pop	bp
	ret
_writeword ENDP

_TEXT	ENDS
	END






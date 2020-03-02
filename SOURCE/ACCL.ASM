;****************************************************************************
;* TurboRacer 286 ACCELerator software                                      *
;* -----------------------------------                                      *
;*                                                                          *
;* (C) 1987,1988 P.D. Smart.                                                *
;*                                                                          *
;*                                                                          *
;* This file contains assembly language routines to implement I/O server    *
;* functions, under the control of the Accelerator board. Also contained    *
;* within this file are assembly language routines to bind to the main C    *
;* program to implement link communications.                                *
;*                                                                          *
;* HISTORY                                                                  *
;* -------                                                                  *
;*                                                                          *
;* V1.0 - Basic program structure prepared and implemented.                 *
;*                                                                          *
;*                                                                          *
;**************************************************************************** 
	TITLE 	Routines to do link communications, and serving.

;* Necessary declarations to enable these assembly language routines to be 
;* linked into the main C program.    
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


;* Global data segment. Any Global data variables must be declared here.   
_DATA	SEGMENT
_DATA	ENDS	


;* All assembly coding must be included within a TEXT segment, a peculiarity
;* of the Microsoft assembler.  
_TEXT	SEGMENT

;****************************************************************************
; SETUP() - Routine to initialise the PC I/O server. Keyboard and Timer tick*
;           interrupts are revectored, stack pointers altered to a new      *
;           storage space, and the I/O server is activated. Should the      *
;           accelerator require termination, through user request, or un-   *
;           recoverable error, then the keyboard and Timer tick vectors are *
;           changed back to there original values, along with the stack     *
;           pointers. Then control is returned back to the calling C        *
;           program, along with a reason code for termination.              *
;									    *
; INPUT: None.                                                              *
;                                                                           *
; OUTPUT: Termination code in AX.                                           *
;****************************************************************************
	PUBLIC	_setup
_setup	PROC	NEAR
	cli
	push	bp			;Save all used registers.
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	mov	ax,0000h		;Revector necessary interrupts.
	mov	ds,ax
	mov	word ptr cs:segsave,ss
	mov	word ptr cs:stksave,sp
	mov	ax,word ptr ds:[0024h]
	mov	word ptr cs:keyip,ax
	mov	ax,word ptr ds:[0026h]
	mov	word ptr cs:keycs,ax
	mov	ax,word ptr ds:[0070h]
	mov	word ptr cs:tickip,ax
	mov	ax,word ptr ds:[0072h]
	mov	word ptr cs:tickcs,ax
	mov	bx,OFFSET _keybi
	mov	word ptr ds:[0024h],bx
	mov	word ptr ds:[0026h],cs
	mov	bx,OFFSET _ticki
	mov	word ptr ds:[0070h],bx
	mov	word ptr ds:[0072h],cs
	push	cs
	push	cs
	push	cs
	pop	ds
	pop	es
	pop	ss
	mov	sp,OFFSET tos		;Change to new TOP OF STACK.
	sti
	jmp	_control		;Execute I/O server.
_set1:	cli
	mov	ss,word ptr cs:segsave	;Restore old stack.
	mov	sp,word ptr cs:stksave
	push	ax
	mov	ax,0000h		;Restore old vectors.
	mov	ds,ax
	mov	ax,word ptr cs:keyip
	mov	word ptr ds:[0024h],ax	
	mov	ax,word ptr cs:keycs
	mov	word ptr ds:[0026h],ax	
	mov	ax,word ptr cs:tickip
	mov	word ptr ds:[0070h],ax	
	mov	ax,word ptr cs:tickcs
	mov	word ptr ds:[0072h],ax	
	sti
	pop	ax			;Restore old registers.
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	bp
	ret
_setup	ENDP

;****************************************************************************
; CONTROL - Routine to perform I/O server functions for the TurboRacer 286  *
;           multiprocessor board. Routine polls the LINK status port until  *
;           a command becomes available, then, via means of a function      *
;           table, jumps to the necessary code to perform the service       *
;           request.                                                        *
;									    *
; INPUT: None.                                                              *
;                                                                           *
; OUTPUT: Termination code in AH.                                           *
;****************************************************************************
_control PROC	NEAR
	mov	si,OFFSET lodmes
	push	cs
	pop	ds
cont_1:	lodsb				;Get byte addressed by SI. SI+1.
	cmp	al,0ffh			;End of message.
	je	cont_2
	mov	ah,0eh			;Do a write teletype.
	mov	bx,7
	mov	cx,1
	push	si
	int	10h
	pop	si
	jmp	cont_1
cont_2:	mov	dx,0211h
cont_3:	in	al,dx			;Await a command.			
	test	al,8
	jnz	cont_3
	dec	dx
	in	al,dx			;Get command.
	cmp	al,(COM_TAE-COM_TAB)/2	;Get address of service routine.
	jb	cont_4
       	mov	al,00h
cont_4:	mov	cl,al
	xor	ch,ch
	shl	cx,1
	mov	bx,OFFSET COM_TAB
	add	bx,cx
	call	word ptr cs:[bx]	;And execute service routine.
	jmp	cont_2
;*
;* I/O service routine table. Contains addresses for all service routines.
;*
COM_TAB	dw	bad_com			;00h
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	_intr5
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	_intr10			;10h
	dw	_intr11
	dw	bad_com
	dw	bad_com
	dw	_intr14
	dw	bad_com
	dw	bad_com
	dw	_intr17
	dw	bad_com
	dw	bad_com
	dw	_intr1a
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com			;20h    
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	disk_reset		;30h
	dw	disk_status
	dw	disk_read
	dw	disk_write
	dw	disk_verf
	dw	disk_parms
	dw	disk_type
	dw	disk_change
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	bad_com
	dw	end_com			;3Fh
COM_TAE	equ	$

;*
;* If this routine is executed, then an unrecoverable error occurred on the
;* TurboRacer 286. Reason code contained in AL. 
;*
bad_com:mov	ah,1			;Indicate error in AH.
	jmp	_set1
;*
;* This routine is executed if the user requests a termination. 
;*
end_com:mov	ah,0			;Indicate termination in AH.
	jmp	_set1

;*
;* Message to indicate that the TurboRacer has control over the PC
;*
lodmes:	db	'Accelerator running.......',0DH,0AH,0FFH
_control ENDP

;****************************************************************************
; KEYBI   - This routine replaces the standard IBM PC interrupt handler.    *
;           Routine passes keyboard code directly to the TurboRacer via     *
;           interrupting the 80286 processor.                               *
;									    *
; INPUT: None.                                                              *
;                                                                           *
; OUTPUT: None.                                                             *
;****************************************************************************
_keybi	PROC	NEAR
	sti				;Interrupts back on.
	push	ax			;Save all registers used.
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	cli
	mov	dx,0211h		;Wait until LINK is clear.
keyb1:	in	al,dx
	test	al,1
	jz	keyb1
	mov	al,06h
	out	dx,al
	nop
	nop
	nop
	nop
	mov	al,02h
	out	dx,al
	dec	dx
	mov	al,09h
	out	dx,al
	mov	dx,0211h
keyb2:	in	al,dx
	test	al,1
	jz	keyb2
	in	al,60h
	push	ax
	in	al,61h
	mov	ah,al
	or	al,80h
	out	061h,al
	xchg	ah,al
	out	061h,al
	pop	ax
	dec	dx
	out	dx,al
	mov	al,20h
	out	20h,al
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret
_keybi	ENDP
	
_ticki	PROC	NEAR
	sti
	push	ax
	push	dx
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	mov	dx,0211h
tick1:	in	al,dx
	test	al,1
	jz	tick1
	cli
	mov	al,06h
	out	dx,al
	nop
	nop
	nop
	mov	al,02h
	out	dx,al
	dec	dx
	mov	al,01ch
	out	dx,al
	sti
ticke:	pop	ds
	pop	dx
	pop	ax
	sti
	iret
_ticki	ENDP
	

_intr5	PROC	NEAR
	int	05h
	mov	bx,0
	mov	ax,50h
	mov	ds,ax
	mov	al,ds:[bx]
	call	txbyte
	ret
_intr5	ENDP	


_intr10	PROC	NEAR
	mov	di,sp			;Save stack pointer.
	mov	ax,8000h
	mov	ds,ax
	mov	es,ax
	call	rxword			;Get AX from link.
	push	ax			;And save on stack.
	call	rxword			;Next BX.
	push	ax
	call	rxword			;Next CX.
	push	ax
	call	rxword			;Next DX.
	push	ax
	mov	bp,sp			;BP addresses stack.
	mov	ax,[bp+6]		;Get AX.
	mov	bx,OFFSET tbs
	cmp	ah,13h			;Write string?
	jne	i10_2
	mov	cx,[bp+2]		;Get count.
i10_1:	call	rxbyte	  		;Read in string.
	mov	es:[bx],al
	inc	bx			;Next byte.
	loop	i10_1
i10_2:	mov	ax,[bp+6]		;Restore AX,BX,CX,DX.
	mov	bx,[bp+4]
	mov	cx,[bp+2]
	mov	dx,[bp]
	mov	bp,OFFSET tbs
	int	10h
	call	txword			;Return AX.
	mov	ax,bx	
	call	txword			;Return BX.
	mov	ax,cx	
	call	txword			;Return CX.
	mov	ax,dx
	call	txword			;Return DX.     
	mov	sp,di
	ret
_intr10 ENDP

_intr11	PROC	NEAR
	int	11h
	call	txword			;Return AX.
	ret
_intr11	ENDP


disk_reset PROC	NEAR	
	mov	ax,0000h
	mov	ds,ax
	mov	bx,ds:[0078h]		;Get parameters pointers.
	mov	ax,ds:[007ah]
	mov	ds,ax
	mov	cx,0bh
dsk_res:call	rxbyte
	mov	ds:[bx],al
	inc	bx
	loop	dsk_res
	mov	ax,0000h		;Get back AX.
	int	13h
	pushf
	call	txword			;Send AX.
	popf
	lahf
	mov	al,ah
	call	txbyte			;Send flags.
	ret
disk_reset ENDP

disk_status PROC NEAR
	mov	ax,0100h
	int	13h
	pushf
	call	txword			;Send AX.
	popf
	lahf
	mov	al,ah
	call	txbyte			;Send flags.
	ret
disk_status ENDP

disk_read PROC	NEAR
	push	cs
	pop	es
	mov	dx,0211h
diskr1:	in	al,dx 			;Read in AL.
	test	al,8
	jnz	diskr1
	dec	dx
	in	al,dx
	mov	ah,02h				    
	push	ax
	push	ax			;Two copies.
	inc	dx
diskr2:	in	al,dx 			;Read in CL.
	test	al,8
	jnz	diskr2
	dec	dx
	in	al,dx
	mov	bl,al
	inc	dx
diskr3:	in	al,dx 			;Read in CH.
	test	al,8
	jnz	diskr3
	dec	dx
	in	al,dx
	mov	bh,al
	push	bx
	inc	dx
diskr4:	in	al,dx			;Read in DL.
	test	al,8
	jnz	diskr4
	dec	dx
	in	al,dx
	mov	bl,al
	inc	dx
diskr5:	in	al,dx 			;Read in DH.
	test	al,8
	jnz	diskr5
	dec	dx
	in	al,dx
	mov	bh,al
	mov	dx,bx
	pop	cx
	pop	ax
	mov	bx,OFFSET tbs
	int	13h
	pop	dx			;Get AX copy int DX.
	pushf
	push	ax
	mov	ax,dx     		;Work out size to transfer.
	xor	ah,ah
	mov	cx,0200h
	mul	cx
	mov	cx,ax
diskr6:	mov	dx,0211h
diskr7:	in	al,dx
	test	al,1			;Check link status.
	jz	diskr7
	dec	dx
	mov	al,es:[bx]
	out	dx,al	
	inc	bx
	loop	diskr6
	pop	ax
	call	txword			;Send AX.
	popf
	lahf
	mov	al,ah
	call	txbyte			;Send flags.
	ret
disk_read ENDP

disk_write PROC	NEAR
	push	cs
	pop	es
	mov	dx,0211h
diskw1:	in	al,dx 			;Read in AL.
	test	al,8
	jnz	diskw1
	dec	dx
	in	al,dx
	mov	ah,03h 
	mov	cx,ax				    
	push	ax			;Two copies.
	inc	dx
diskw2:	in	al,dx 			;Read in CL.
	test	al,8
	jnz	diskw2
	dec	dx
	in	al,dx
	mov	bl,al
	inc	dx
diskw3:	in	al,dx 			;Read in CH.
	test	al,8
	jnz	diskw3
	dec	dx
	in	al,dx
	mov	bh,al
	push	bx
	inc	dx
diskw4:	in	al,dx			;Read in DL.
	test	al,8
	jnz	diskw4
	dec	dx
	in	al,dx
	mov	bl,al
	inc	dx
diskw5:	in	al,dx 			;Read in DH.
	test	al,8
	jnz	diskw5
	dec	dx
	in	al,dx
	mov	bh,al
	push	bx
	mov	bx,OFFSET tbs			;Write a sector.
	mov	ax,cx	
	xor	ah,ah
	mov	cx,0200h
	mul	cx
	mov	cx,ax
diskw6:	mov	dx,0211h
diskw7:	in	al,dx
	test	al,8
	jnz	diskw7
	dec	dx
	in	al,dx
	mov	es:[bx],al
	inc	bx
	loop	diskw6
	pop	dx
	pop	cx
	pop	ax
	mov	bx,OFFSET tbs
	int	13h
	pushf
	call	txword			;Send AX.
	popf
	lahf
	mov	al,ah
	call	txbyte			;Send flags.
	ret
disk_write ENDP

disk_verf PROC 	NEAR
	push	cs
	pop	es
	mov	bx,OFFSET tbs
	call	rxword
	push	ax
	call	rxword
	push	ax
	call	rxword
	mov	dx,ax
	pop	cx
	pop	ax
	int	13h
	pushf
	call	txword			;Send AX.
	popf
	lahf
	mov	al,ah
	call	txbyte			;Send flags.
	ret
disk_verf ENDP


disk_parms PROC	NEAR
	call	rxword
	push	ax
	call	rxword
	mov	dx,ax
	pop	ax
	int	13h
	pushf
	call	txword			;Send AX.
	mov	ax,cx
	call	txword			;Send CX.
	mov	ax,dx
	call	txword			;Send DX.
	popf
	lahf
	mov	al,ah
	call	txbyte			;Send flags.
	ret
disk_parms ENDP


disk_type PROC	NEAR
disk_change:
	call	rxword
	int	13h
	pushf
	call	txword			;Send AX.
	mov	ax,dx
	call	txword			;Send DX.
	popf
	lahf
	mov	al,ah
	call	txbyte			;Send flags.
	ret
disk_type ENDP


_intr14	PROC	NEAR
	call	rxword			;Read AX.
	push	ax
	call	rxword			;Read DX.
	mov	dx,ax
	pop	ax
	int	14h
	call	txword			;Return AX.
	ret
_intr14	ENDP


_intr17	PROC	NEAR
	call	rxword			;Read AX.
	push	ax
	call	rxword			;Read DX.
	mov	dx,ax
	pop	ax
	int	17h
	call	txword			;Return AX.
	ret
_intr17	ENDP

_intr1a	PROC	NEAR
	call	rxword
	push	ax   			;Save AX.
	call	rxword
	mov	cx,ax			;Get CX.
	call	rxword
	mov	dx,ax			;Get DX.
	pop	ax			;Restore AX.
	int	1ah
	pushf
	call	txword			;Return AX.
	mov  	ax,cx
	call	txword			;Return CX.
	mov	ax,dx
	call	txword			;Return DX.
	popf
	lahf
	mov	al,ah
	call	txbyte			;Return flags.
	ret	
_intr1a	ENDP


;***************************************
; Read a byte from link.               *
;***************************************
rxbyte	PROC	NEAR
	cli
	push	dx
	mov	dx,0211h
rxb1:	in	al,dx
	test	al,8
	jnz	rxb1
	dec	dx
	in	al,dx
	xor	ah,ah
	pop	dx
	sti
	ret
rxbyte	ENDP


;***************************************
; Read a word from link.               *
;***************************************
rxword 	PROC	NEAR
	cli
	push	dx
	mov	dx,0211h
rxw1:	in	al,dx
	test	al,8
	jnz	rxw1
	dec	dx
	in	al,dx 			;Read in LOW byte.
	mov	ah,al
	inc	dx
rxw2:	in	al,dx
	test	al,8
	jnz	rxw2
	dec	dx
	in	al,dx			;Read in HIGH byte.
	xchg	al,ah			;Right order.
	pop	dx
	sti
	ret
rxword	ENDP


;***************************************
; Write a byte to link.                *
;***************************************
txbyte 	PROC	NEAR
	cli
	push	ax
	push	dx
	mov	ah,al
	mov	dx,0211h
txb1:	in	al,dx
	test	al,1			;Check link status.
	jz	txb1
	dec	dx
	mov	al,ah
	out	dx,al			;Transfer.
	pop	dx
	pop	ax
	sti
	ret
txbyte	ENDP


;***************************************
; Write a word to link.                *
;***************************************
txword 	PROC	NEAR
	cli
	push	ax
	push	dx
	push	ax
	mov	dx,0211h
txw1:	in	al,dx
	test	al,1
	jz	txw1
	dec	dx
	pop	ax
	out	dx,al			;Transfer LOW byte.
	inc	dx
txw2:	in	al,dx
	test	al,1
	jz	txw2
	dec	dx
	mov	al,ah
	out	dx,al 			;Transfer HIGH byte.
	pop	dx
	pop	ax
	sti
	ret
txword	ENDP

CODEEND equ	$			;End of reusable code.

	PUBLIC	_readlink
_readlink PROC	NEAR
	push	bp
	mov	bp,sp
	mov	dx,0211h
rd1:	in	al,dx
	test	al,00001000b
	jnz	rd1
	dec	dx
	in	al,dx
	xor	ah,ah
	mov	sp,bp
	pop	bp
	ret
_readlink ENDP

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

	PUBLIC	_intstat
_intstat PROC	NEAR
	push	bp
	mov	dx,0211h
	in	al,dx
	test	al,00000010b
	mov	al,1
	jz	ints
	mov	al,0
ints:	xor	ah,ah
	pop	bp
	ret
_intstat ENDP

	PUBLIC	_writelink
_writelink PROC NEAR
	push	bp
	mov	bp,sp
	mov	dx,0211h
wr1:	in	al,dx
	test	al,00000001b
	jz	wr1
	mov	ax,[bp+4]
	dec	dx
	out	dx,al
	mov	sp,bp
	pop	bp
	ret
_writelink ENDP

_locald	PROC	NEAR
dataseg	equ	$
tbs	db	02000h dup(?)		;8192 byte temporary buffer.
dskt	db	0ch dup(?)		;11 byte Disk parameter buffer.
	db	02000h dup(?)
tos	equ	$			;8192 byte stack.
segsave	dw	00000H
stksave	dw	00000H
keyip	dw	00000H
keycs	dw	00000H
tickip	dw	00000H
tickcs	dw	00000H
_locald	ENDP


_TEXT	ENDS
	END







;***************************************
; Display AX as a hex value on VIDEO   *
;***************************************
DHEX:	PUSH	AX		;Store AX, print AH.
	MOV	AL,AH
	CALL	HEX
	POP	AX
	CALL	HEX  		;Print AL.
	RET

;***************************************
; Display AL as a hex value on VIDEO   *
;***************************************
HEX:	PUSH	BX		;Store registers used.
	PUSH	CX
	PUSH	DX
	PUSH	AX
	AND	AL,0F0H		;High nibble first.
	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	CALL	HEX1		;Print
	POP	AX
	AND	AL,0FH		;Now low nibble.
	CALL	HEX1
	MOV	AL,20H
	MOV	AH,0EH
	MOV	BL,7
	INT	10H
	POP	DX
	POP	CX
	POP	BX
	RET
HEX1:	CMP	AL,0AH
	JL	HEX2
	ADD	AL,07H
HEX2:	ADD	AL,30H
    	MOV	AH,0EH
	MOV	BL,7
	INT	10H
	RET



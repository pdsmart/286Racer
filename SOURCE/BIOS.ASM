;****************************************************************************
;** BIOS.ASM                                                               **
;** --------                                                               **
;**                                                                        **
;** (C) 1987, 1988 P.D. Smart                                              **
;**                                                                        **
;** This file is part of the TURBOROM.ASM source code. It contains code    **
;** to perform:-                                                           **
;**                                                                        **
;** All PC compatible ROM bios functions, making the 286 + 1Mbyte RAM      **
;** appear as a fast PC compatible.                                        **
;** Reset boot jump.                                                       **
;**                                                                        **
;** These routines reside at ROM location FC00:2000 - FC00:3FFF            **
;**                                                                        **
;****************************************************************************

	ORG	02000H		  	;Beginning of BIOS code.

;***************************************
; NMI interrupt.                       *
;                                      *
; FUNCTION: NMI service routine to     *
;           process requests from the  *
;           PC.                        *
; TYPE: 286 service required.          *
;***************************************
NMI:	PUSH	AX			;Save used registers.
	PUSH	DX
	STI				;Interrupts back on.
	MOV	DX,0C02H
NMI1:	IN	AL,DX			;Wait for descriptor byte.
	TEST	AL,8
	JNZ	NMI1			
	DEC	DX
	DEC	DX			;Get descriptor byte. 
	IN	AL,DX			;What action does the PC request?
	CMP	AL,09H			;Keyboard?
	JNZ	NMI2
	INC	DX
	INC	DX
NMIK:	IN	AL,DX	      		;If keyboard, get scan code from PC.
	TEST	AL,8
	JNZ	NMIK
	DEC	DX
	DEC	DX
	IN	AL,DX
	INT	09H			;And perform a keyboard interrupt.
	JMP	NMIEXIT
NMI2:	CMP	AL,01CH	     		;Timer tick?
	JNZ	NMI3
	INT	01CH			;If timer tick, perform a timer
	JMP	NMIEXIT			;tick interrupt.
NMI3:	
NMIEXIT:POP	DX			;Restore used registers.
	POP	AX
	STI
	IRET
;*******************************
; End of NMI servicing.        *
;*******************************


;***************************************
; Interrupt number 5. PRINT_SCREEN.    *
;                                      *
; FUNCTION: Initiates a dump of the    *
;           screen to printer.         *
; TYPE: PC service required.           *
;***************************************
INTR5:	CLI				;Disable further interrupts.
	PUSH	AX
	PUSH	BX
	PUSH	DX
	PUSH	DS
	MOV	AL,05H
	CALL	TXCOM			;Send command.
	CALL	RXBYTE
	SUB	BX,BX
	MOV	DS,BX
	MOV	BX,500			;Address of Print screen variable.
	MOV	[BX],AL			;Store.
	POP	DS
	POP	DX
	POP	BX
	POP	AX
	STI				;Re-enable interrupts.
	IRET
;*******************************
; End of Interrupt 5.          *
;*******************************

;***************************************
; Interrupt number 10H. VIDEO_IO       *
;                                      *
; FUNCTION: Processes video input &    *
;           output.                    *
; TYPE: PC service required.           *
;***************************************
INTR10:	CLI				;Disable further interrupts.
	PUSH	AX
	PUSH	AX
	MOV	AL,10H
	CALL	TXCOM
	POP	AX
	CALL	TXWORD			;Send AX.
	MOV	AX,BX
	CALL	TXWORD			;Send BX.
	MOV	AX,CX
	CALL	TXWORD			;Send CX.
	MOV	AX,DX
	CALL	TXWORD			;Send DX.
	POP	AX
	CMP	AH,13H			;Write string?.
	JNE	I10_2			;No, go on.
	PUSH	BP			;If write string, transfer all
I10_1:	MOV	AL,ES:[BP]		;bytes found at ES:BP.
	INC	BP
	CALL	TXBYTE			;Send byte.
	LOOP	I10_1
	POP	BP	
I10_2:	CALL	RXWORD			;Receive AX.
	PUSH	AX
	CALL	RXWORD
	MOV	BX,AX			;Receive BX.
	CALL	RXWORD
	MOV	CX,AX			;Receive CX.
	CALL	RXWORD
	MOV	DX,AX			;Receive DX.
	POP	AX	
	STI				;Re-enable interrupts.
	IRET
;*******************************
; End of VIDEO I/O.            *
;*******************************

;***************************************
; Interrupt number 11. EQUIPMENT CHECK *
;                                      *
; FUNCTION: Checks to see what equip-  *
;           ment is present.           *
; TYPE: PC service required.           *
;***************************************
INTR11:	CLI				;Disable further interrupts.
	MOV	AL,11H
	CALL	TXCOM
	CALL	RXWORD			;Receive AX.
	STI				;Re-enable interrupts.
	IRET
;*******************************
; End of Equipment check.      *
;*******************************

;***************************************
; Interrupt number 12H.MEMORY CHECK    *
;                                      *
; FUNCTION: Indicates how much memory  *
;           is present.                *
; TYPE: Fixed value returned.          *
;***************************************
INTR12:	CLI				;Disable further interrupts.
	MOV	AX,0280H		;Full complement of memory.
	STI				;Re-enable interrupts.
	IRET
;*******************************
; End of Memory check.         *
;*******************************

;***************************************
; Interrupt number 13.DISK DRIVE I/O.  *
;                                      *
; FUNCTION: Disk drive input & output  *
;           processing.                *
; TYPE: PC service required.           *
;***************************************
INTR13:	STI				;Enable interrupts.
	PUSH	BP
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DS
	MOV	BP,SP			;BP to point to parameter base.
	;
	CMP	AH,31
	JB	I131			;> Max parameter, point to bad.
	MOV	AH,14H
I131:	MOV	CL,AH
	XOR	CH,CH			;Index into function table for
	SHL	CX,1			;subroutine address.
	MOV	BX,OFFSET DSK_TAB
	ADD	BX,CX
	CALL	CS:[BX]			;Call subroutine.
	POP	DS
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	POP	BP
	STI				;Re-enable interrupts.
	RETF	0002H			;Throw old flags away.
;***************************************
; Table of subroutine addresses.       *
;***************************************
DSK_TAB:DW	D_RESET
	DW	D_STATUS
	DW	D_READ
	DW	D_WRITE
	DW	D_VERF
	DW	D_ERR			;Any format operation is error.
	DW	D_ERR
	DW	D_ERR
	DW	D_PARMS
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_TYPE
	DW	D_CHANGE
	DW	D_ERR			;Any format operation is error.
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
	DW	D_ERR
DSK_TAE:
;***************************************
; Disk reset.                          *
;***************************************
D_RESET:MOV	AL,30H
	CALL	TXCOM			;Pass command to PC server.
	MOV	AX,0000H		;Send across table.
	MOV	DS,AX
	MOV	BX,DS:[0078H]
	MOV	AX,DS:[007AH]
	MOV	DS,AX			;DS:BX point to disk table.
	MOV	CX,0BH			;Eleven bytes to transfer.
D_RES1:	MOV	AL,DS:[BX]
	CALL	TXBYTE
	INC	BX
	LOOP	D_RES1			;Transer table.
	JMP	D_V1
;***************************************
; Disk status.                         *
;***************************************
D_STATUS:
	MOV	AL,31H			;Pass command to PC server.
	CALL	TXCOM
	JMP	D_V1			;Use dupilicate code.
;***************************************
; Disk read.                           *
;***************************************
D_READ:	MOV	AL,32H			;Pass command to PC server.
	CALL	TXCOM
	MOV	AX,[BP+8]
	CALL	TXBYTE			;Transmit AL.
	MOV	AX,[BP+4]
	CALL	TXWORD			;Transmit CX.
	MOV	AX,[BP+2]
	CALL	TXWORD			;Transmit DX.
	MOV	AX,[BP+8]
	MOV	CX,0200H		;Calculate transfer size.
	XOR	AH,AH
	MUL	CX
	MOV	CX,AX
	MOV	BX,[BP+6]		;Address for load.
D_READ1:CALL	RXBYTE			;Read in bytes, into memory.
	MOV	ES:[BX],AL
	INC	BX
	LOOP	D_READ1
	JMP	D_V1
;***************************************
; Disk write.                          *
;***************************************
D_WRITE:MOV	AL,33H			;Pass command to PC server.
	CALL	TXCOM
	MOV	AX,[BP+8]
	CALL	TXBYTE			;Transmit AL.
	MOV	AX,[BP+4]
	CALL	TXWORD			;Transmit CX.
	MOV	AX,[BP+2]
	CALL	TXWORD			;Transmit DX.
	MOV	AX,[BP+8]
	MOV	CX,0200H		;Calculate transfer size.
	XOR	AH,AH
	MUL	CX
	MOV	CX,AX			;Number of bytes to transfer.
	MOV	BX,[BP+6]		;Address for write.
D_WRIT1:MOV	AL,ES:[BX]		;Get byte.
	CALL	TXBYTE       
	INC	BX
	LOOP	D_WRIT1			;Loop until all transfered.
	JMP	D_V1
;***************************************
; Disk verify.                         *
;***************************************
D_VERF:	MOV	AL,34H			;Pass command to PC server.
	CALL	TXCOM
	MOV	AX,[BP+8]
	CALL	TXWORD			;Transmit AX.
	MOV	AX,[BP+4]
	CALL	TXWORD			;Transmit CX.
	MOV	AX,[BP+2]
	CALL	TXWORD			;Transmit DX.
D_V1:	CALL	RXWORD	 		;Get AX.
	MOV	[BP+8],AX
D_V2:	CALL	RXBYTE			;Get flags.
	MOV	AH,AL
	SAHF				;Store flags.
	RET
;***************************************
; Disk parameters read.                *
;***************************************
D_PARMS:MOV	AL,35H			;Pass command to PC server.
	CALL	TXCOM
	MOV	AX,[BP+8]		;Transmit AX.
	CALL	TXWORD
	MOV	AX,[BP+2]
	CALL	TXWORD			;Transmit DX.
	CALL	RXWORD
	MOV	[BP+8],AX		;Read in AX.
	CALL	RXWORD
	MOV	[BP+4],AX		;Read in CX.
	CALL	RXWORD
	MOV	[BP+2],AX		;Read in DX.
	JMP	D_V2
;***************************************
; Disk type read.                      *
;***************************************
D_TYPE:	MOV	AL,36H			;Pass command to PC server.
D_T1:	CALL	TXCOM
	MOV	AX,[BP+8]
	CALL	TXWORD			;Transmit AX.
	CALL	RXWORD
	MOV	[BP+8],AX		;New AX.
	CALL	RXWORD
	MOV	[BP+2],AX		;New DX.
     	JMP	D_V2
;***************************************
; Disk change.                         *
;***************************************
D_CHANGE:				;Pass command to PC server.
	MOV	AL,37H
	JMP	D_T1
;***************************************
; Error due to bad parameters.         *
;***************************************
D_ERR:	MOV	AX,[BP+8]		;Return error code in AH & CARRY.
	MOV	AH,1
	MOV	[BP+8],AX
	STC
	RET
;*******************************
; End of DISK I/O.             *
;*******************************

;***************************************
; Interrupt number 14H.RS232 I/O.      *
;                                      *
; FUNCTION: RS-232 input & output      *
;           processing.                *
; TYPE: PC service required.           *
;***************************************
INTR14:	CLI				;Disable further interrupts.
	PUSH	AX
	MOV	AL,14H			;Pass command to PC server.
	CALL	TXCOM
	POP	AX
	CALL	TXWORD			;Transmit AX.
	MOV	AX,DX
	CALL	TXWORD			;Transmit DX.
	CALL	RXWORD			;Receive AX.
	STI				;Re-enable interrupts.
	IRET
;*******************************
; End of RS-232 I/O.           *
;*******************************

;***************************************
; Interrupt number 15H.CASSETTE I/O.   *
;                                      *
; FUNCTION: Cassette input & output    *
;           processing.                *
; TYPE: Unimplemented.                 *
;***************************************
INTR15:	STI				;Re-enable interrupts.
	IRET
;*******************************
; End of CASSETTE I/O.         *
;*******************************

;***************************************
; Interrupt number 16H.KEYBOARD I/O.   *
;                                      *
; NB. The following code is a diss-    *
; assembly of a standard keyboard      *
; handler present under DOS. It has    *
; been suitably modified to work on the*
; accelerator board.                   *
;                                      *
; FUNCTION: Keyboard input & output    *
;           processing.                *
; TYPE: Internal servicing.            *
;***************************************
INTR16:	STI
	PUSH	DS			;Save registers.
	PUSH	BX
	PUSH	AX
	MOV	AX,0040H		;Test for accelerator termination
	MOV	DS,AX			;code.
	POP	AX
	CMP	WORD PTR RESET_FLAG,1234H
	JNE	INT16_1
	MOV	AL,03FH			;Terminate accelerator.
	CALL	TXCOM
INT16_1:OR	AH,AH
	JZ	K1			;Read next character?
	DEC	AH
	JZ	K2			;Status?
	DEC	AH
	JZ	K3			;Shift status?
INTEND:	POP	BX
	POP	DS
	IRET
K1:   	MOV	BX,WORD PTR BUFFER_HEAD	                                  
	CMP	BX,WORD PTR BUFFER_TAIL	                 
	JZ	K1
	MOV	AX,[BX]
	CALL	K4			
	MOV	WORD PTR BUFFER_HEAD,BX
	JMP	SHORT INTEND
K2:	CLI
	MOV	BX,WORD PTR BUFFER_HEAD
	CMP	BX,WORD PTR BUFFER_TAIL
	MOV	AX,[BX]
	STI
	POP	BX
	POP	DS
	RETF	0002H
K3:	MOV	AL,BYTE PTR KB_FLAG
	JMP	SHORT INTEND
K4:	INC	BX
	INC	BX
	CMP	BX,WORD PTR BUFFER_END
	JNE	K5
	MOV	BX,WORD PTR BUFFER_START
K5:	RET
;
K6:	DB	INS_KEY
	DB	CAPS_KEY,NUM_KEY,SCROLL_KEY,ALT_KEY,CTL_KEY
	DB	LEFT_KEY,RIGHT_KEY
K6B:
K6L	EQU	K6B-K6
;
K7:	DB	INS_SHIFT
	DB	CAPS_SHIFT,NUM_SHIFT,SCROLL_SHIFT,ALT_SHIFT,CTL_SHIFT
	DB	LEFT_SHIFT,RIGHT_SHIFT
;
K8:	DB	27,-1,0,-1,-1,-1,30,-1
	DB	-1,-1,-1,31,-1,127,-1,17
	DB	23,5,18,20,25,21,9,15
	DB	16,27,29,10,-1,1,19
	DB	4,6,7,8,10,11,12,-1,-1
	DB	-1,-1,28,26,24,3,22,2
	DB	14,13,-1,-1,-1,-1,-1,-1
	DB	' ',-1
K9:	DB	94,95,96,97,98,99,100,101
	DB	102,103,-1,-1,119,-1,132,-1
	DB	115,-1,116,-1,117,-1,118,-1
	DB	-1
K10:	DB	01BH,'1234567890-=',08H,09H
	DB	'qwertyuiop[]',0DH,-1,'asdfghjkl;',027H
	DB	'#',-1,5CH,'zxcvbnm,./',-1,'*',-1,' '
	DB	-1
K11:	DB	27,'!"œ$',37,05EH,'&*()_+',08H,0
	DB	'QWERTYUIOP{}',0DH,-1,'ASDFGHJKL:@'
	DB	07EH,-1,'|ZXCVBNM<>?',-1,0,-1,' ',-1
K12:	DB	84,85,86,87,88,89,90
	DB	91,92,93
K13:	DB	104,105,106,107,108
	DB	109,110,111,112,113
K14:	DB	'789-456+1230.'
K15:	DB	71,72,73,-1,75,-1,77
	DB	-1,79,80,81,82,83
;
KB_INT:	STI
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
	PUSH	DI
	PUSH	DS
	PUSH	ES
	CLD
	PUSH	AX
	MOV	AX,0040H
	MOV	DS,AX
	POP	AX
	MOV	AH,AL
	CMP	AL,0FFH
	JNZ	K16
	JMP	K62
K16:	AND	AL,07FH
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET K6
	MOV	CX,K6L
	REPNE	SCASB
	MOV	AL,AH
	JE	K17
	JMP	K25
K17:	SUB	DI,OFFSET K6+1
	MOV	AH,CS:K7[DI]
	TEST	AL,80H
	JNZ	K23
	CMP	AH,SCROLL_SHIFT
	JAE	K18
	OR	BYTE PTR KB_FLAG,AH
	JMP	K26
K18:	TEST	BYTE PTR KB_FLAG,CTL_SHIFT
	JNZ	K25
	CMP	AL,INS_KEY
	JNZ	K22
	TEST	BYTE PTR KB_FLAG,ALT_SHIFT
	JNZ	K25
K19:	TEST	BYTE PTR KB_FLAG,NUM_STATE
	JNZ	K21
	TEST	BYTE PTR KB_FLAG,LEFT_SHIFT+RIGHT_SHIFT
	JZ	K22
K20:	MOV	AX,5230H
	JMP	K57
K21:	TEST	BYTE PTR KB_FLAG,LEFT_SHIFT+RIGHT_SHIFT
	JZ	K20
K22:	TEST	AH,BYTE PTR KB_FLAG_1
	JNZ	K26
	OR	BYTE PTR KB_FLAG_1,AH
	XOR	BYTE PTR KB_FLAG,AH
	CMP	AL,INS_KEY
	JNE	K26
	MOV	AX,INS_KEY*256
	JMP	K57
K23:	CMP	AH,SCROLL_SHIFT
	JAE	K24
	NOT	AH
	AND	BYTE PTR KB_FLAG,AH
	CMP	AL,ALT_KEY+80H
	JNE	K26
	MOV	AL,BYTE PTR ALT_INPUT
	MOV	AH,0
	MOV	BYTE PTR ALT_INPUT,AH
	CMP	AL,0
	JE	K26
	JMP	K58
K24:	NOT	AH
	AND	BYTE PTR KB_FLAG_1,AH
	JMP	SHORT K26
K25:	CMP	AL,80H
	JAE	K26
	TEST	BYTE PTR KB_FLAG_1,HOLD_STATE
	JZ	K28
	CMP	AL,NUM_KEY
	JE	K26
	AND	BYTE PTR KB_FLAG_1,NOT HOLD_STATE
K26:	CLI
K27:	POP	ES
	POP	DS
	POP	DI
	POP	SI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	IRET
K28:	TEST	BYTE PTR KB_FLAG,ALT_SHIFT
	JNZ	K29
	JMP	K38
K29:	TEST	BYTE PTR KB_FLAG,CTL_SHIFT
	JZ	K31
	CMP	AL,DEL_KEY
	JNE	K31
	MOV	WORD PTR RESET_FLAG,1234H
	JMP	K26
K30:	DB	82,79,80,81,75,76,77
	DB	71,72,73
	DB	16,17,18,19,20,21,22,23
	DB	24,25,30,31,32,33,34,35
	DB	36,37,38,44,45,46,47,48
	DB	49,50
K31:	CMP	AL,57
	JNE	K32
	MOV	AL,' '
	JMP	K57
K32:	MOV	DI,OFFSET K30
	MOV	CX,10
	REPNE	SCASB
	JNE	K33
	SUB	DI,OFFSET K30+1
	MOV	AL,BYTE PTR ALT_INPUT
	MOV	AH,10
	MUL	AH
	ADD	AX,DI
	MOV	BYTE PTR ALT_INPUT,AL
	JMP	K26
K33:	MOV	BYTE PTR ALT_INPUT,0
	MOV	CX,26
	REPNE	SCASB
	JNE	K34
	MOV	AL,0
	JMP	K57
K34:	CMP	AL,2
	JB	K35
	CMP	AL,14
	JAE	K35
	ADD	AH,118
	MOV	AL,0
	JMP	K57
K35:	CMP	AL,59
	JAE	K37
K36:	JMP	K26
K37:	CMP	AL,71
	JAE	K36
	MOV	BX,OFFSET K13
	JMP	K63
K38:	TEST	BYTE PTR KB_FLAG,CTL_SHIFT
	JZ	K44
	CMP	AL,SCROLL_KEY
	JNE	K39
	MOV	BX,WORD PTR BUFFER_START
	MOV	WORD PTR BUFFER_HEAD,BX
	MOV	WORD PTR BUFFER_TAIL,BX
	MOV	BYTE PTR BIOS_BREAK,80H
	INT	1BH
	SUB	AX,AX
	JMP	K57
K39:	CMP	AL,NUM_KEY
	JNE	K41
	OR	BYTE PTR KB_FLAG_1,HOLD_STATE
K40:	TEST	BYTE PTR KB_FLAG_1,HOLD_STATE
	JNZ	K40
	JMP	K27
K41:	CMP	AL,55
	JNE	K42
	MOV	AX,114*256
	JMP	K57
K42:	MOV	BX,OFFSET K8
	CMP	AL,59
	JB	K56
K43:	MOV	BX,OFFSET K9
	JMP	K63
K44:	CMP	AL,71
	JAE	K48
	TEST	BYTE PTR KB_FLAG,LEFT_SHIFT+RIGHT_SHIFT
	JZ	K54
	CMP	AL,15
	JNE	K45
	MOV	AX,15*256
	JMP	SHORT K57
K45:	CMP	AL,55
	JNE	K46
	INT	05H
	JMP	K27
K46:	CMP	AL,59
	JB	K47
	MOV	BX,OFFSET K12
	JMP	K63
K47:	MOV	BX,OFFSET K11
	JMP	SHORT K56
K48:	TEST	BYTE PTR KB_FLAG,NUM_STATE
	JNZ	K52
	TEST	BYTE PTR KB_FLAG,LEFT_SHIFT+RIGHT_SHIFT
	JNZ	K53
K49:	CMP	AL,74
	JE	K50
	CMP	AL,78
	JE	K51
	SUB	AL,71
	MOV	BX,OFFSET K15
	JMP	SHORT K64
K50:	MOV	AX,74*256+'-'
	JMP	SHORT K57
K51:	MOV	AX,78*256+'+'
	JMP	SHORT K57
K52:	TEST	BYTE PTR KB_FLAG,LEFT_SHIFT+RIGHT_SHIFT
	JNZ	K49
K53:	SUB	AL,70
	MOV	BX,OFFSET K14
	JMP	SHORT K56
K54:	CMP	AL,59
	JB	K55
	MOV	AL,0
	JMP	SHORT K57
K55:	MOV	BX,OFFSET K10
K56:	DEC	AL
	XLAT 	CS:K11
K57:	CMP	AL,-1
	JE	K59
	CMP	AH,-1
	JE	K59
K58:	TEST	BYTE PTR KB_FLAG,CAPS_STATE
	JZ	K61
	TEST	BYTE PTR KB_FLAG,LEFT_SHIFT+RIGHT_SHIFT
	JZ	K60
	CMP	AL,'A'
	JB	K61
	CMP	AL,'Z'
	JA	K61
	ADD	AL,'a'-'A'
	JMP	SHORT K61
K59:	JMP	K26
K60:	CMP	AL,'a'
	JB	K61
	CMP	AL,'z'
	JA	K61
	ADD	AL,'a'-'A'
K61:	MOV	BX,WORD PTR BUFFER_TAIL
	MOV	SI,BX
	CALL	K4
	CMP	BX,WORD PTR BUFFER_HEAD
	JE	K62
	MOV	[SI],AX
	MOV	WORD PTR BUFFER_TAIL,BX
	JMP	K26
K63:	SUB	AL,59
K64:	XLAT	CS:K9
	MOV	AH,AL
	MOV	AL,0
	JMP	K57
K62:	JMP	K27			;Bell sounded here.
;*******************************
; End of KEYBOARD I/O.         *
;*******************************

;***************************************
; Interrupt number 17.PRINTER I/O.     *
;                                      *
; FUNCTION: Printer input & output     *
;           processing.                *
; TYPE: PC service required.           *
;***************************************
INTR17:	CLI				;Disable further interrupts.
	PUSH	AX
	MOV	AL,17H
	CALL	TXCOM
	POP	AX
	CALL	TXWORD			;Transmit AX.
	MOV	AX,DX
	CALL	TXWORD			;Transmit DX.
	CALL	RXWORD			;Receive AX.
	STI				;Re-enable interrupts.
	IRET
;*******************************
; End of PRINTER I/O.          *
;*******************************
	
;***************************************
; Interrupt number 1AH.CLOCK I/O.      *
;                                      *
; FUNCTION: Clock input & output       *
;           processing.                *
; TYPE: PC service required.           *
;***************************************
INTR1A:	CLI				;Disable further interrupts.
	PUSH	AX
	MOV	AL,1AH
	CALL	TXCOM
	POP	AX
	CALL	TXWORD			;Send AX.
	MOV	AX,CX
	CALL	TXWORD			;Send CX.
	MOV	AX,DX
	CALL	TXWORD			;Send DX.
	CALL	RXWORD			;Get AX.
	PUSH	AX
	CALL	RXWORD			;Get CX.
	MOV	CX,AX
	CALL	RXWORD			;Get DX.
	MOV	DX,AX
	CALL	RXBYTE
	MOV	AH,AL
	SAHF
	POP	AX	
	STI				;Re-enable interrupts.
	RETF	0002H			;Throw away old flags.
;*******************************
; End of CLOCK I/O.            *
;*******************************

;***************************************
; Bootstrap loader.                    *
;***************************************
BOOTSTRAP:
	STI				;Interrupts back on.
	MOV	AX,0040H
	MOV	DS,AX
	MOV	BYTE PTR INTR_FLAG,00H
	MOV	WORD PTR RS232_BASE,03F8H
	MOV	WORD PTR RS232_BASE+2,0000H
	MOV	WORD PTR PRINTER_BASE,03BCH
	MOV	WORD PTR EQUIP_FLAG,4260H
	MOV	BYTE PTR MFG_TST,00H
	MOV	WORD PTR MEMORY_SIZE,0280H
	MOV	WORD PTR MFG_ERR_FLAG,0000H
	MOV	BYTE PTR KB_FLAG,00H
	MOV	WORD PTR PRINT_TIM_OUT,01E1EH
	MOV	WORD PTR PRINT_TIM_OUT+2,01E1EH
	MOV	WORD PTR RS232_TIM_OUT,0101H
	MOV	WORD PTR RS232_TIM_OUT+2,0101H
	MOV	WORD PTR BUFFER_START,001EH
	MOV	WORD PTR BUFFER_END,003EH
	MOV	WORD PTR BUFFER_HEAD,001EH
	MOV	WORD PTR BUFFER_TAIL,001EH
	MOV	WORD PTR RESET_FLAG,00000H
H0:	SUB	AX,AX
	MOV	DS,AX
	MOV	WORD PTR 0078H,DISK_BASE
	MOV	WORD PTR 007AH,CS
	MOV	DX,0000H
	MOV	CX,3
H1:	PUSH	CX
	MOV	AH,0
	INT	13H
	JC	H2
	MOV	AX,0000H
	MOV	ES,AX
	MOV	AX,201H
	MOV	BX,07C00H
	MOV	CX,1
	INT	13H
H2:	POP	CX
	JNC	H4
	LOOP	H1
	MOV	DX,0080H
	MOV	CX,4
	JMP	H1
H3:	PUSH	DS
	MOV	AX,0FC00H
	MOV	DS,AX
	MOV	SI,BADMES
	CALL	PRNTS
	MOV	AH,0
	INT	16H			;Wait until a key is struck.
	POP	DS
	JMP	H0	
H4:	PUSH	DS
	MOV	AX,0003H
	INT	10H
	MOV	AX,0FC00H
	MOV	DS,AX
	MOV	SI,ACCEL		;Tell user accelerating.
	CALL	PRNTS
	POP	DS
	JMP	0000:7C00
;*******************************
; End of BOOTSTRAP.            *
;*******************************

;***************************************
; Read a byte from link.               *
;***************************************
RXBYTE:	PUSH	DX
	MOV	DX,0C02H
RXB1:	IN	AL,DX
	TEST	AL,8
	JNZ	RXB1
	DEC	DX
	DEC	DX
	IN	AL,DX
	XOR	AH,AH
	POP	DX
	RET
;*******************************
; End of READ BYTE.            *
;*******************************

;***************************************
; Read a word from link.               *
;***************************************
RXWORD:	PUSH	DX
	MOV	DX,0C02H
RXW1:	IN	AL,DX
	TEST	AL,8
	JNZ	RXW1
	DEC	DX
	DEC	DX
	IN	AL,DX 			;Read in LOW byte.
	MOV	AH,AL
	INC	DX
	INC	DX
RXW2:	IN	AL,DX
	TEST	AL,8
	JNZ	RXW2
	DEC	DX
	DEC	DX
	IN	AL,DX			;Read in HIGH byte.
	XCHG	AL,AH			;Right order.
	POP	DX
	RET
;*******************************
; End of READ WORD.            *
;*******************************

;***************************************
; Write a command to link.             *
;***************************************
TXCOM:	PUSH	DX
	MOV	AH,AL
	MOV	DX,0C02H
	MOV	AL,1
	OUT	DX,AL			;Enable PC interrupts for command.
TXC1:	IN	AL,DX
	TEST	AL,1			;Check link status.
	JZ	TXC1
	DEC	DX
	DEC	DX
	MOV	AL,AH			;Command to send.
	OUT	DX,AL			;Send.
	NOP
	NOP
	NOP
	NOP
	MOV	DX,0C02H
	MOV	AL,0
	OUT	DX,AL			;Disable PC interrupts.
	POP	DX
	RET
;*******************************
; End of WRITE command.        *
;*******************************

;***************************************
; Write a byte to link.                *
;***************************************
TXBYTE:	PUSH	AX
	PUSH	DX
	MOV	AH,AL
	MOV	DX,0C02H
TXB1:	IN	AL,DX
	TEST	AL,1			;Check link status.
	JZ	TXB1
	DEC	DX
	DEC	DX
	MOV	AL,AH
	OUT	DX,AL			;Transfer.
	POP	DX
	POP	AX
	RET
;*******************************
; End of WRITE BYTE.           *
;*******************************

;***************************************
; Write a word to link.                *
;***************************************
TXWORD:	PUSH	AX
	PUSH	DX
	PUSH	AX
	MOV	DX,0C02H
TXW1:	IN	AL,DX
	TEST	AL,1
	JZ	TXW1
	DEC	DX
	DEC	DX
	POP	AX
	OUT	DX,AL			;Transfer LOW byte.
	INC	DX
	INC	DX
TXW2:	IN	AL,DX
	TEST	AL,1
	JZ	TXW2
	DEC	DX
	DEC	DX
	MOV	AL,AH
	OUT	DX,AL			;Transfer HIGH byte.
	POP	DX
	POP	AX
	RET
;*******************************
; End of WRITE WORD.           *
;*******************************

;***************************************
; Illegal or unimplemented interrupts  *
; are serviced by the following group  *
; of subroutines. Basically, unimplem- *
; ented interrupts return immediately, *
; Illegal interrupts pass a code back  *
; to the PC server.                    *
;***************************************
INTRAP0:PUSH	AX
	MOV	AL,00h
INTRG:	CALL	TXCOM
	POP	AX
INTRAP:	STI
	IRET

INTRAP1:PUSH	AX
	MOV	AL,01h
	JMP	SHORT INTRG

INTRAP3:PUSH	AX
	MOV	AL,03h
	JMP	SHORT INTRG

INTRAP4:PUSH	AX
	MOV	AL,04h
	JMP	SHORT INTRG

INTRAP5:PUSH	AX
	MOV	AL,05h
	JMP	SHORT INTRG

INTRAP6:PUSH	AX
	MOV	AL,06h
	JMP	SHORT INTRG

INTRAP7:PUSH	AX
	MOV	AL,07h
	JMP	SHORT INTRG

INTRAP8:PUSH	AX
	MOV	AL,08h
	JMP	SHORT INTRG

INTRAPA:PUSH	AX
	MOV	AL,0Ah
	JMP	SHORT INTRG

INTRAPB:PUSH	AX
	MOV	AL,0Bh
	JMP	SHORT INTRG

INTRAPC:PUSH	AX
	MOV	AL,0Ch
	JMP	SHORT INTRG

INTRAPD:PUSH	AX
	MOV	AL,0Dh
	JMP	SHORT INTRG

INTRAPE:PUSH	AX
	MOV	AL,0Eh
	JMP	SHORT INTRG

INTRAPF:PUSH	AX
	MOV	AL,0Fh
	JMP	SHORT INTRG

INTRAP18:PUSH	AX
	MOV	AL,18h
	JMP	SHORT INTRG

INTRAP1D:PUSH	AX
	MOV	AL,1Dh
	JMP	SHORT INTRG

INTRAP1E:PUSH	AX
	MOV	AL,1Eh
	JMP	SHORT INTRG

INTRAP1F:PUSH	AX
	MOV	AL,1Fh
	JMP	SHORT INTRG
;*******************************
; End of ILLEGAL & UNIMPLEMEN- *
; TED interrupts.              *
;*******************************


;***************************************
; BIOS data storage.                   *
;***************************************
	ORG	03F00H			

;***************************************
; Storage for DISKETTE parameters.     *
;***************************************
DISK_BASE: 				;Initial disk drive parameters.
	DB	0DFH
	DB	2
	DB	25H
	DB	02H
	DB	9
	DB	02AH
	DB	0FFH
	DB	050H
	DB	0F6H
	DB	00fH
	DB	02H
;*******************************
; End of DISKETTE parameters.  *
;*******************************

;***************************************
; Storage for HARD DISK parameters.    *
;***************************************
HARD_BASE:
	DB	032H,001H,002H,032H,001H,000H,000H,00BH
	DB	000H,00CH,0B4H,028H,000H,000H,000H,000H
	DB	032H,001H,004H,032H,001H,000H,000H,00BH
	DB	005H,00CH,0B4H,028H,000H,000H,000H,000H
	DB	032H,001H,006H,080H,000H,000H,001H,00BH
	DB	005H,00CH,0B4H,028H,000H,000H,000H,000H
	DB	064H,002H,002H,000H,000H,080H,000H,00BH
	DB	005H,018H,0F0H,040H,000H,000H,000H,000H
;*******************************
; End of HARD DISK parameters. *
;*******************************

;***************************************
; Storage for BIOS messages.           *
;***************************************
FORMES:	DB	'Format operations cannot be executed whilst in ACCELERATOR '
	DB	'mode.',0DH,0AH
	DB	'Rebooting of PC necessary.',0DH,0AH,0FFH
;*******************************
; End of BIOS messages.        *
;*******************************

;***************************************
; RESET vector upon power up or reset. *
;***************************************
	ORG	03FF0H 			;Reset boot up start.

	JMP	0FC00:0000		;Go to startup code.
;***************************************
; Release date information.            *
;***************************************
	DB	'04/04/88'
	DB	0AAH,00FEH,05DH

	ORG	03FFFH			;Required to get object file to
;****************************************************************************
;** End of the TurboRacer 286 coding. An object file of 16384 bytes should **
;** be generated.                                                          **
;****************************************************************************






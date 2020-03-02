;****************************************************************************
;** STARTUP.ASM                                                            **
;** -----------                                                            **
;**                                                                        **
;** (C) 1987, 1988 P.D. Smart                                              **
;**                                                                        **
;** This file is part of the TURBOROM.ASM source code. It contains code    **
;** to perform:-                                                           **
;**                                                                        **
;** FC00:0000 -> CPU test code,                                            **
;**              Memory test code,                                         **
;**              Basic initiator code,                                     **
;**                :- Load in new BIOS.                                    **
;**                :- Load in test code.                                   **
;**                :- Execute memory exercise code.                        **
;**                :- Boot up DOS using BIOS in rom.                       **
;**                                                                        **
;** These routines reside at ROM location FC00:0000                        **
;**                                                                        **
;****************************************************************************


STARTUP:MOV	DX,0C00H	;Read scrap data out of link.
	IN	AL,DX	
;*******************************
; Test 80286 processor.        *
;*******************************
	;Test 80286 flags.
	CLI			;Disable interrupts.
	MOV	AH,0D5H		;Set SF, CF, ZF, and AF flags on.
	SAHF
	JNC	E1		;Error if CF not set.
	JNZ	E1		;Error if ZF not set.
	JNP	E1		;Error if PF not set.
	JNS	E1		;Error if SF not set.
	LAHF	    		;Load flag image to AH.
	MOV	CL,5
	SHR	AH,CL		;Shift AF into carry.
	JNC	E1		;Error if AF not set.
	MOV	AL,40H
	SHL	AL,1
	JNO	E1		;Error if OF not set.
	XOR	AH,AH
	SAHF			;Clear SF, CF, ZF and PF.
	JBE	E1		;Error if CF, ZF set.
	JS	E1		;Error if SF set.
	JP	E1		;Error if PF set.
	LAHF	
	SHR	AH,CL
	JC	E1		;Error if AF set.
	SHL	AH,1
	JO	E1		;Error if OF set.
	;Test 80286 registers
	MOV	AX,0FFFFH
	STC
PT1:	MOV	DS,AX	        ;Write all registers.
	MOV	BX,DS
	MOV	ES,BX
	MOV	CX,ES
	MOV	SS,CX
	MOV	DX,SS
	MOV	SP,DX
	MOV	BP,SP
	MOV	SI,BP
	MOV	DI,SI
	JNC	PT2
	XOR	AX,DI		;Pattern make it through registers.
	JNZ	E1		;Error if it didnt.
	CLC
	JMP	PT1
PT2:	OR	AX,DI
	JZ	MT
E1:	MOV	AL,1		;Processor error code.
	JMP	ESEND
;*******************************
; End of 80286 testing.        *
;*******************************

;*******************************
; Test lower 512K of memory.   *
;*******************************	
MT:	MOV	AX,0	
	MOV	DS,AX		;DS points to 64K segment.
MT0:	MOV	BX,0		;BX points to offset within segment.
	MOV	CX,07FFFH	;CX = number of writes per segment.
MT1:	MOV	AX,0FFFFH	;First load FF's into memory.
	MOV	[BX],AX
	MOV	AX,[BX]
	CMP	AX,0FFFFH	;Check to see if memory retained FF's.
	JNE	MT2
	MOV	AX,0000H	;Load 00's into memory.
	MOV	[BX],AX
	MOV	AX,[BX]		;Check to see if memory retained 00's.
	CMP	AX,0000H
	JNE	MT2
	MOV	AX,05555H	;Load 55's into memory.
	MOV	[BX],AX
	MOV	AX,[BX]		
	CMP	AX,05555H	;Check to see if memory retained 55's.
	JNE	MT2
	MOV	AX,0AAAAH	;Load AA's into memory.
	MOV	[BX],AX
	MOV	AX,[BX]
	CMP	AX,0AAAAH	;Check to see if memory retained AA's.
	JNE	MT2
	MOV	AX,055AAH	;Now try a mixed combination.
	MOV	[BX],AX
	MOV	AX,[BX]
	CMP	AX,055AAH	;Check to see if retained.
	JNE	MT2
	MOV	AX,00000H	;Load in 0000's to clear memory.
	MOV	[BX],AX
	INC	BX
	INC	BX
	LOOP	MT1		;Loop until count exhausted.
	MOV	AX,DS
	ADD	AX,1000H	;Move to next data segment.
	MOV	DS,AX	        
	CMP	AX,8000H	;If DS>=8000H, then 512K checked, exit.
	JNE	MT0
	MOV	AL,0		;AL = Memory test pass code.
	JMP	ESEND
MT2:	MOV	AL,2		;AL = Memory test fail code.
ESEND: 	MOV	AH,AL
	MOV	DX,0C02H
ES1:	IN	AL,DX		;Determine if link is clear to send data.
	TEST	AL,1
	JZ	ES1		;If not, wait until clear.
	MOV	DX,0C00H
	MOV	AL,AH		;Send error code.
	OUT	DX,AL
	CMP	AL,0
	JE	LDT		;Jump to load tables if no errors.
	CMP	AL,2
	JNE	ES2
	JMP	MEMTEST
ES2:	HLT			;Halt if error.
;*******************************
; End of memory testing.       *
;*******************************

;*******************************
; Setup H/W interrupt tables.  *
;*******************************
LDT:	MOV	AX,0FC00H
	MOV	DS,AX
	MOV	AX,00000H
	MOV	ES,AX
	MOV	SI,INTTAB	;Address of table in ROM.
	MOV	DI,0		;Base of memory.
	MOV	CX,0200H	;Transfer 32 vectors.
	REP MOVSW	  	;Transfer.
;*******************************
; End of table setup.          *
;*******************************

;*******************************
; Command mode.                *
;*******************************
CM:	MOV	AX,0FC00H
	MOV	DS,AX		;Setup data segment and extra segment.
	MOV	ES,AX
	MOV	AX,00000H
	MOV	SS,AX		;Setup stack segment.
	MOV	SP,0500H	;Setup Top Of Stack.
	;
CM1:	CALL	RXBYTE		;Get a command from PC.
	CMP	AL,1
	JE	BOOT		;If command is 1, BOOT up DOS.
	CMP	AL,2
	JNE	CM2    		;If command is 2, Copy resident BIOS into
	JMP	CBIOS		;memory then BOOT up DOS.
CM2:	CMP	AL,3	
	JE	LBIOS		;If command is 3, load BIOS code from PC.
	CMP	AL,4
	JE	LOADT		;If command is 4, load TEST code from PC.
	CMP	AL,5
	JE	LMEMT		;If command is 5, execute interactive memory 
	JMP	CM1		;testing code.
;*******************************
; End of command mode.         *
;*******************************

BOOT:	JMP	BOOTSTRAP
LMEMT:	JMP	MEMTEST

;***************************************
; Load a new BIOS in from the PC over  *
; the link.                            *
;***************************************
LBIOS:	MOV	CX,4000H	;BIOS must be 16K long.
	MOV	BX,0000H	;Start loading at segment FC00:0000.
LBS1:	CALL	RXBYTE		;Get byte.
	MOV	DS:[BX],AL
	INC	BX		;Store in memory, then back for next byte.
	LOOP	LBS1
	MOV	AX,0		;In order to execute the new BIOS, the ROM
	MOV	ES,AX		;has to be paged out. As the ROM, and high
	MOV	SI,LTAB1	;memory reside in the same space, a special
	MOV	DI,0		;piece of code has to be executed in low
	MOV	CX,10		;memory. Thus transfer the necessary code
	REP MOVSB		;into low memory.
	JMP	0000:0000	;And execute.
;*******************************
; End of new BIOS load.        *
;*******************************


;***************************************
; Load a test program in from the PC.  *
;***************************************
LOADT:	MOV	AX,1000H	;Segment to load code in = 1000:0000.
	MOV	DS,AX
	MOV	BX,0000H
	CALL	RXBYTE		;Get code size. Can't be >64Kbyte. 
	MOV	CL,AL
	CALL	RXBYTE
	MOV	CH,AL		;Load count from link.
LDT1:	CALL	RXBYTE
	MOV	DS:[BX],AL	;Load test code into memory.
	INC	BX
	LOOP	LDT1		;Continue for code size.
	JMP	1000:0000
;*******************************
; End of test code loader.     *
;*******************************

;***************************************
; Copy resident BIOS into RAM, then    *
; boot up DOS.                         *
;***************************************
CBIOS:	MOV	BX,00000H	;Start at segment FC00:0000
	MOV	CX,1FFFH	;8k words to transfer.
CB1:	MOV	AX,[BX]		;Transfer by doing a read/write to the
	MOV	[BX],AX 	;same location.
	INC	BX
	INC	BX
	LOOP	CB1
	MOV	DX,0C04H 	;Page out ROM. Due to RAM occupying same
	OUT	DX,AL		;address space as ROM, and RAM containing
				;a copy of ROM, execution will continue in 
				;RAM.
	JMP	BOOTSTRAP

;***************************************
; Print string.                        *
;***************************************
PRNTS:	PUSH	DS  		;Store all registers used.
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	CS
	POP	DS
PRNTS1:	LODSB			;Get byte addressed by SI. SI+1.
	CMP	AL,0FFH		;End of message.
	JE	PRNE
	MOV	AH,0EH		;Do a write teletype.
	MOV	BX,7
	MOV	CX,1
	PUSH	SI
	INT	10H
	POP	SI
	JMP	PRNTS1
PRNE:	POP	DX		;Recover all registers.
	POP	CX
	POP	BX
	POP	AX
	POP	DS
	RET
;*******************************
; End of print string.         *
;*******************************

































	


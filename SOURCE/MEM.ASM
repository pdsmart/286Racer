;****************************************************************************
;** MEM.ASM                                                                **
;** -------                                                                **
;**                                                                        **
;** (C) 1987, 1988 P.D. Smart                                              **
;**                                                                        **
;** This file is part of the TURBOROM.ASM source code. It contains code    **
;** to perform interactive memory testing. As the code is stored in low    **
;** memory, it will normally be written over during normal DOS operations. **
;**                                                                        **
;**                                                                        **
;****************************************************************************

;***************************************
; Memory exerciser code.               *
;                                      *
; FUNCTION: Interactively tests 80286  *
;           1M RAM system.             *
;***************************************
MEMTEST:MOV	AX,0FC00H	        ;Print out message indicating 
	MOV	DS,AX	                ;interactive memory test code on line.
	MOV	SI,MESBOOT
X1:	LODSB				;NB. All code has to be written with
	CMP	AL,0FFH			;out using stack or memory storage.
	JE	X3
	MOV	AH,AL
	MOV	DX,0C02H
X2:	IN	AL,DX
	TEST	AL,1
	JZ	X2
	MOV	DX,0C00H
	MOV	AL,AH
	OUT	DX,AL
	JMP	X1
X3:	MOV	DX,0C02H		;Once message printed out, await a
X4:	IN	AL,DX			;command from the IBM PC.
	TEST	AL,8			;Poll status port. Data available?
	JNZ	X4
	MOV	DX,0C00H
	IN	AL,DX			;Get data.
	CMP	AL,1			;Read memory?
	JE	MEM1
	CMP	AL,2			;Write memory?
	JE	MEM2
	CMP	AL,3			;Partial memory test?
	JE	MEM3
	CMP	AL,4		        ;Full memory test?
	JE	MEM4
	CMP	AL,5			;Memory search?
	JE	MEM5
	MOV	SI,MESILC		;If illegal command, print out illegal
X5:	LODSB				;command message.
	CMP	AL,0FFH
	JE	X7
	MOV	AH,AL
	MOV	DX,0C02H
X6:	IN	AL,DX
	TEST	AL,1
	JZ	X6
	MOV	DX,0C00H
	MOV	AL,AH
	OUT	DX,AL
	JMP	X5
X7:	JMP	X3

MEM2:	JMP	N0			;At conditional jump only has a 
MEM3:	JMP	MTEST			;limited range, thus these jumps
MEM4:	JMP	FULL			;are needed to jump to routines
MEM5:	JMP	SRCH			;located over 128 bytes away.

;***************************************
; Read memory.                         *
;                                      *
; FUNCTION: Dump memory to PC in HEX   *
;           form. PC supplies the      *
;           addresses to dump between. *
;***************************************
MEM1:	MOV	DX,0C02H		;First of all, get parameters from
M1:	IN	AL,DX			;IBM PC.
	TEST	AL,8			;Wait until a byte appears in link
	JNZ	M1			;data register.
	MOV	DX,0C00H
	IN	AL,DX			;Get byte.
	MOV	BL,AL			;Store as low byte, getting a word.
	MOV	DX,0C02H
M2:	IN	AL,DX			;Wait until a byte appears in link
	TEST	AL,8			;data register.
	JNZ	M2
	MOV	DX,0C00H
	IN	AL,DX			;Get byte.
	MOV	BH,AL		        ;Get DS first (start segment).
	MOV	AX,BX
	MOV	DS,AX
	MOV	DX,0C02H
M3:	IN	AL,DX
	TEST	AL,8
	JNZ	M3
	MOV	DX,0C00H
	IN	AL,DX
	MOV	BL,AL
	MOV	DX,0C02H
M4:	IN	AL,DX
	TEST	AL,8
	JNZ	M4
	MOV	DX,0C00H
	IN	AL,DX
	MOV	BH,AL		        ;Get BX next (start address).
	MOV	DX,0C02H
M5:	IN	AL,DX
	TEST	AL,8
	JNZ	M5
	MOV	DX,0C00H
	IN	AL,DX
	MOV	CL,AL
	MOV	DX,0C02H
M6:	IN	AL,DX
	TEST	AL,8
	JNZ	M6
	MOV	DX,0C00H
	IN	AL,DX
	MOV	CH,AL
	MOV	AX,CX
	MOV	SS,AX		        ;Get SS next (end segment).
	MOV	DX,0C02H
M7:	IN	AL,DX
	TEST	AL,8
	JNZ	M7
	MOV	DX,0C00H
	IN	AL,DX
	MOV	CL,AL
	MOV	DX,0C02H
M8:	IN	AL,DX
	TEST	AL,8
	JNZ	M8
	MOV	DX,0C00H
	IN	AL,DX
	MOV	CH,AL
	MOV	BP,CX	        	;Get BP next (end address).
M10:	MOV	DX,0C02H
M11:	IN	AL,DX
	TEST	AL,1
	JZ	M11
	MOV	DX,0C00H
	MOV	AL,DS:[BX]		;Get a byte from memory,
	OUT	DX,AL		        ;Send data.
	MOV	AX,DS
	MOV	DX,SS
	CMP	AX,DX			;End of dump?
	JNE	M12
	MOV	AX,BP
	CMP	AX,BX
	JNE	M12
	JMP	X3
M12:	INC	BX
	CMP	BX,00000H
	JNE	M10
	MOV	AX,DS
	ADD	AX,1000H
	MOV	DS,AX
	JMP	M10


;***************************************
; Write memory.                        *
;                                      *
; FUNCTION: Write XX to memory. PC     *
;           supplies the start address,*
;           end address, and XX.       *
;***************************************
N0:	MOV	DX,0C02H		;First of all, get parameters from
N1:	IN	AL,DX			;IBM PC.
	TEST	AL,8
	JNZ	N1
	MOV	DX,0C00H
	IN	AL,DX
	MOV	BL,AL
	MOV	DX,0C02H
N2:	IN	AL,DX
	TEST	AL,8
	JNZ	N2
	MOV	DX,0C00H
	IN	AL,DX
	MOV	BH,AL		        ;Get DS first (start segment).
	MOV	AX,BX
	MOV	DS,AX
	MOV	DX,0C02H
N3:	IN	AL,DX
	TEST	AL,8
	JNZ	N3
	MOV	DX,0C00H
	IN	AL,DX
	MOV	BL,AL
	MOV	DX,0C02H
N4:	IN	AL,DX
	TEST	AL,8
	JNZ	N4
	MOV	DX,0C00H
	IN	AL,DX
	MOV	BH,AL		        ;Get BX next (start address).
	MOV	DX,0C02H
N5:	IN	AL,DX
	TEST	AL,8
	JNZ	N5
	MOV	DX,0C00H
	IN	AL,DX
	MOV	CL,AL
	MOV	DX,0C02H
N6:	IN	AL,DX
	TEST	AL,8
	JNZ	N6
	MOV	DX,0C00H
	IN	AL,DX
	MOV	CH,AL
	MOV	AX,CX
	MOV	SS,AX		        ;Get SS next (end segment).
	MOV	DX,0C02H
N7:	IN	AL,DX
	TEST	AL,8
	JNZ	N7
	MOV	DX,0C00H
	IN	AL,DX
	MOV	CL,AL
	MOV	DX,0C02H
N8:	IN	AL,DX
	TEST	AL,8
	JNZ	N8
	MOV	DX,0C00H
	IN	AL,DX
	MOV	CH,AL
	MOV	BP,CX		        ;Get BP next (end address).
	MOV	DX,0C02H
N9:	IN	AL,DX
	TEST	AL,8
	JNZ	N9
	MOV	DX,0C00H
	IN	AL,DX
	MOV	CL,AL 		        ;Get data to write into memory.
N10:	MOV	DS:[BX],CL		;Write data to memory.
	MOV	AX,DS
	MOV	DX,SS
	CMP	AX,DX
	JNE	N11
	MOV	AX,BP
	CMP	AX,BX
	JNE	N11
	JMP	X3
N11:	INC	BX			;End of block write?
	CMP	BX,00000H
	JNE	N10
	MOV	AX,DS
	ADD	AX,1000H
	MOV	DS,AX
	JMP	N10

;***************************************
; Partial memory test.                 *
;                                      *
; FUNCTION: Performs a byte/word read/ *
;           write to lower 512K memory *
;           block. Writes different    *
;           values into memory to catch*
;           out any faulty bit.        *
;***************************************
MTEST:	MOV	AX,0			;Prepare to test memory.
	MOV	DS,AX			
ST0:	MOV	BX,0			;Have to do the job in 8*64K segments
	MOV	CX,0FFFFH
ST1:	MOV	AX,55AAH		;Write a word 55AAH firstly.
	MOV	[BX],AX
	NOP
	NOP
	MOV	AX,[BX]			;Check to see if memory store it 
	CMP	AX,55AAH		;correctly.
	JNE	ERR1
	MOV	AX,0AA55H		;Try the same word but bytes reversed
	MOV	[BX],AX
	NOP
	NOP
	MOV	AX,[BX]			;Memory stored it correctly?
	CMP	AX,0AA55H
	JNE	ERR2
	MOV	AX,00FFH		;Now try 00FFH.
	MOV	[BX],AX
	NOP
	NOP
	MOV	AX,[BX]			;Memory stored it correctly?
	CMP	AX,00FFH
	JNE	ERR3
	MOV	AX,0FF00H		;Reverse of above word.
	MOV	[BX],AX
	NOP
	NOP
	MOV	AX,[BX]			;Memory stored it correctly?
	CMP	AX,0FF00H
	JNE	ERR4
	MOV	AL,00H			;Now try a byte write.
	MOV	[BX],AL
	NOP
	NOP
	MOV	AL,[BX]			;Was the byte stored?
	CMP	AL,00H
	JNE	ERR5
	MOV	AL,0FFH			;Now try the complement of above byte
	MOV	[BX],AL
	NOP
	NOP
	MOV	AL,[BX]			;Was the byte stored?
	CMP	AL,0FFH
	JNE	ERR6
	INC	BX			;Move onto next byte.
	MOV	AL,00H			;And try the byte writes on the 
	MOV	[BX],AL			;other byte in word pair.
	NOP
	NOP
	MOV	AL,[BX]
	CMP	AL,00H
	JNE	ERR7
	MOV	AL,0FFH
	MOV	[BX],AL
	NOP
	NOP
	MOV	AL,[BX]
	CMP	AL,0FFH
	JNE	ERR8
	MOV	ES,AX
	LOOP	ST1			;Loop until 64K segment tested.
	MOV	AX,DS
	ADD	AX,1000H		;All 8 segments tested?
	MOV	DS,AX
	CMP	AX,8000H
	JNE	ST0
	MOV	AL,0
	JMP	ERR
ERR1:	MOV	ES,AX			;If an error occurred, inform the PC.
	MOV	AL,1
	JMP	ERR
ERR2:	MOV	ES,AX
	MOV	AL,2
	JMP	ERR
ERR3:	MOV	ES,AX
	MOV	AL,3
	JMP	ERR
ERR4:	MOV	ES,AX
	MOV	AL,4
	JMP	ERR
ERR5:	MOV	ES,AX
	MOV	AL,5
	JMP	ERR
ERR6:	MOV	ES,AX
	MOV	AL,6
	JMP	ERR
ERR7:	MOV	ES,AX
	MOV	AL,7
	JMP	ERR
ERR8:	MOV	ES,AX
	MOV	AL,8
ERR:  	MOV	AH,AL		
	MOV	DX,0C02H
ER1:	IN	AL,DX
	TEST	AL,1
	JZ	ER1
	MOV	DX,0C00H
	MOV	AL,AH		        ;Send error code.
	OUT	DX,AL
	MOV	DX,0C02H
ER2:	IN	AL,DX
	TEST	AL,1
	JZ	ER2
	MOV	DX,0C00H
	MOV	AX,ES
	OUT	DX,AL		        ;Send AL.
	MOV	DX,0C02H
ER3:	IN	AL,DX
	TEST	AL,1
	JZ	ER3
	MOV	DX,0C00H
	MOV	AX,ES
	MOV	AL,AH		        ;Send AH.
	OUT	DX,AL		
	MOV	DX,0C02H
ER4:	IN	AL,DX
	TEST	AL,1
	JZ	ER4
	MOV	DX,0C00H
	MOV	AL,BL		        ;Send BL.
	OUT	DX,AL
	MOV	DX,0C02H
ER5:	IN	AL,DX
	TEST	AL,1
	JZ	ER5
	MOV	DX,0C00H
	MOV	AL,BH		        ;Send BH.
	OUT	DX,AL
	MOV	DX,0C02H
ER6:	IN	AL,DX
	TEST	AL,1
	JZ	ER6
	MOV	DX,0C00H
	MOV	AX,DS		        ;Send low DS.
	OUT	DX,AL
	MOV	DX,0C02H
ER7:	IN	AL,DX
	TEST	AL,1
	JZ	ER7
	MOV	DX,0C00H
	MOV	AX,DS
	MOV	AL,AH		        ;Send high DS.
	OUT	DX,AL
      	JMP	MEMTEST


;***************************************
; Full memory test code.               *
;                                      *
; FUNCTION: Tests memory in probably   *
;           the best memory test       *
;           possible. Writes zero's to *
;           all memory, writes a 1 to  *
;           1 byte in the memory array *
;           and then scans the entire  *
;           memory array for errors.   *
;***************************************
FULL:	MOV	SI,0000H		;Prepare for memory test.
	MOV	SS,SI
	MOV	BP,SI
MF1:	MOV	DS,SI
MF2:	MOV	BX,SI			
	MOV	CX,7FFFH		;Zero fill entire memory bank.
MF3:	MOV	[BX],SI
	INC	BX
	INC	BX
	LOOP	MF3
	MOV	AX,DS
	ADD	AX,1000H
	MOV	DS,AX
	CMP	AX,8000H
	JNE	MF2
;					;Write a byte of 1's to address 
MF4:	MOV	AL,0FFH			;pointed to by DS:BP.
	MOV	[BP],AL
;
SEARCH:	MOV	DS,SI			;Now search entire memory for any byte
SR0:	MOV	BX,SI			;which has any bit set.
	MOV	CX,07FFFH
SR1:	CMP	[BX],SI
	JE	SR3
SR2:	MOV	AX,SS
	MOV	DX,DS
	CMP	AX,DX
	JNE	SRP
	MOV	AX,BP  			;If address = DS:BP, jump over.
	AND	AX,0FFFEH
	CMP	BX,AX
	JNE	SRP
	JMP	SR3
SRP:   	MOV	ES,AX
    	JMP	FLP
SR3:	INC	BX			;Continue search for entire memory.
	INC	BX
   	LOOP	SR1
	MOV	AX,DS
	ADD	AX,1000H
	MOV	DS,AX
	CMP	AX,8000H
	JNE	SR0
	MOV	AX,SI
	MOV	ES,AX
;
FLP:	MOV	DX,0C02H		;Send to IBM PC, current position
FL1:	IN	AL,DX			;of test.
	TEST	AL,1
	JZ	FL1
	MOV	DX,0C00H
	MOV	AX,SS		        ;Send SS.
	OUT	DX,AL
	MOV	DX,0C02H
FL2:	IN	AL,DX
	TEST	AL,1
	JZ	FL2
	MOV	DX,0C00H
	MOV	AX,SS
	MOV	AL,AH
	OUT	DX,AL		
	MOV	DX,0C02H
FL3:	IN	AL,DX
	TEST	AL,1
	JZ	FL3
	MOV	DX,0C00H
	MOV	AX,BP		        ;Send BP.
	OUT	DX,AL		
	MOV	DX,0C02H
FL4:	IN	AL,DX
	TEST	AL,1
	JZ	FL4
	MOV	DX,0C00H
	MOV	AX,BP
	MOV	AL,AH
	OUT	DX,AL		
	MOV	DX,0C02H
FL5:	IN	AL,DX
	TEST	AL,1
	JZ	FL5
	MOV	DX,0C00H
	MOV	AX,DS		        ;Send DS.
	OUT	DX,AL
	MOV	DX,0C02H
FL6:	IN	AL,DX
	TEST	AL,1
	JZ	FL6
	MOV	DX,0C00H
	MOV	AX,DS
	MOV	AL,AH
	OUT	DX,AL		
	MOV	DX,0C02H
FL7:	IN	AL,DX
	TEST	AL,1
	JZ	FL7
	MOV	DX,0C00H
	MOV	AX,BX		        ;Send BX.
	OUT	DX,AL
	MOV	DX,0C02H
FL8:	IN	AL,DX
	TEST	AL,1
	JZ	FL8
	MOV	DX,0C00H
	MOV	AX,BX
	MOV	AL,AH
	OUT	DX,AL		
	MOV	DX,0C02H
FL9:	IN	AL,DX
	TEST	AL,1
	JZ	FL9
	MOV	DX,0C00H
	MOV	AX,ES  		        ;Send AL.
	OUT	DX,AL
;
	MOV	AL,0			;Zero fill memory, and check to see
	MOV	[BP],AL			;if it is end of test.
	INC	BP
	CMP	BP,SI
	JNE	MQ1
	MOV	AX,SS
	ADD	AX,1000H
	MOV	SS,AX
	CMP	AX,8000H
	JNE	MQ1			;If not, repeat search.
	JMP	MEMTEST
MQ1:	JMP	MF4


;***************************************
; Memory search code.                  *
;                                      *
; FUNCTION: Search memory to check     *
;           that memory is set to a    *
;           particular byte, reporting *
;           to the PC any byte which   *
;           is not correct.            *
;***************************************
SRCH: 	MOV	DX,0C02H		;Get byte from PC to search for.
SRC1:	IN	AL,DX
	TEST	AL,8
	JNZ	SRC1
	MOV	DX,0C00H
	IN	AL,DX
	MOV	AH,AL
	MOV	DI,AX
	MOV	SI,0000H
	MOV	DS,SI
SRC2:	MOV	BX,0000H
	MOV	CX,0FFFFH
SRC3:	MOV	AL,[BX]
	CMP	AL,AH			;If byte is not the same as that 
	JNE	SRC4			;searched for, report to IBM PC.
	INC	BX
	LOOP	SRC3
	MOV	AX,DS
	ADD	AX,1000H
	MOV	DS,AX
	CMP	AX,8000H
	MOV	AX,DI
	JNE	SRC2
	MOV	CX,6
	MOV	DX,0C02H
SRCE:	IN	AL,DX			;End of search?
	TEST	AL,1
	JZ	SRCE
	DEC	DX
	DEC	DX
	MOV	AL,0FFH		        ;If so, send end of search byte.
	OUT	DX,AL
	INC	DX
	INC	DX
	LOOP	SRCE
	JMP	MEMTEST
SRC4:	MOV	SI,AX			;Send details to PC of memory location
	MOV	DX,0C02H		;that was not the same as the search
SRC5:	IN	AL,DX			;value.
	TEST	AL,1
	JZ	SRC5
	MOV	DX,0C00H
	MOV	AX,SI		        ;Send AX.
	OUT	DX,AL
	MOV	DX,0C02H
SRC6:	IN	AL,DX
	TEST	AL,1
	JZ	SRC6
	MOV	DX,0C00H
	MOV	AX,SI
	MOV	AL,AH
	OUT	DX,AL		
	MOV	DX,0C02H
SRC7:	IN	AL,DX
	TEST	AL,1
	JZ	SRC7
	MOV	DX,0C00H
	MOV	AX,DS		        ;Send DS.
	OUT	DX,AL		
	MOV	DX,0C02H
SRC8:	IN	AL,DX
	TEST	AL,1
	JZ	SRC8
	MOV	DX,0C00H
	MOV	AX,DS
	MOV	AL,AH
	OUT	DX,AL		
	MOV	DX,0C02H
SRC9:	IN	AL,DX
	TEST	AL,1
	JZ	SRC9
	MOV	DX,0C00H
	MOV	AX,BX		        ;Send BX.
	OUT	DX,AL
	MOV	DX,0C02H
SRC10:	IN	AL,DX
	TEST	AL,1
	JZ	SRC10
	MOV	DX,0C00H
	MOV	AX,BX
	MOV	AL,AH
	OUT	DX,AL		
	MOV	AX,DI		        ;Get back AX.
	JMP	SRC3
;***************************************
; End of interactive memory test code. *
;***************************************





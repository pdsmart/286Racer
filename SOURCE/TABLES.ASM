;****************************************************************************
;** TABLES.ASM                                                             **
;** ----------                                                             **
;**                                                                        **
;** (C) 1987, 1988 P.D. Smart                                              **
;**                                                                        **
;** This file is part of the TURBOROM.ASM source code. Once the system has **
;** initialised itself, these tables can be overwritten for extra storage  **
;** space. The tables stored are:-                                         **
;**                                                                        **
;** Interrupt vector table,                                                **
;** Memory Read/Write messages,                                            **
;** Boot up messages,                                                      **
;** Bios ROM - RAM code.                                                   **
;**                                                                        **
;** These tables reside at ROM location FC00:1000                          **
;**                                                                        **
;****************************************************************************

	ORG	01000H	  	;Tables at FC00:1000 

;***************************************
; Interrupt Table.                     *
;                                      *
; Contains pointers to all the int's   *
; used on the accelerator board.       *
;***************************************
INTTAB:	DW	INTRAP0		;IP 0
	DW	0FC00H		;CS 
	DW	INTRAP1		;IP 1
	DW	0FC00H		;CS
	DW	NMI		;IP 2
	DW	0FC00H		;CS
	DW	INTRAP3		;IP 3
	DW	0FC00H		;CS
	DW	INTRAP4		;IP 4
	DW	0FC00H		;CS
	DW	INTRAP5		;IP 5
	DW	0FC00H		;CS
	DW	INTRAP6		;IP 6
	DW	0FC00H		;CS
	DW	INTRAP7		;IP 7
	DW	0FC00H		;CS
	DW	INTRAP8		;IP 8
	DW	0FC00H		;CS
	DW	KB_INT		;IP 9
	DW	0FC00H		;CS
	DW	INTRAPA		;IP A
	DW	0FC00H		;CS
	DW	INTRAPB		;IP B
	DW	0FC00H		;CS
	DW	INTRAPC		;IP C
	DW	0FC00H		;CS
	DW	INTRAPD		;IP D
	DW	0FC00H		;CS
	DW	INTRAPE		;IP E
	DW	0FC00H		;CS
	DW	INTRAPF		;IP F
	DW	0FC00H		;CS
	DW	INTR10		;IP 10
	DW	0FC00H		;CS 
	DW	INTR11		;IP 11
	DW	0FC00H		;CS
	DW	INTR12		;IP 12
	DW	0FC00H		;CS
	DW	INTR13		;IP 13
	DW	0FC00H		;CS
	DW	INTR14		;IP 14
	DW	0FC00H		;CS
	DW	INTRAP		;IP 15
	DW	0FC00H		;CS
	DW	INTR16		;IP 16
	DW	0FC00H		;CS
	DW	INTR17		;IP 17
	DW	0FC00H		;CS
	DW	INTRAP18	;IP 18
	DW	0FC00H		;CS
	DW	BOOTSTRAP       ;IP 19
	DW	0FC00H		;CS
	DW	INTR1A		;IP 1A
	DW	0FC00H		;CS
	DW	INTRAP		;IP 1B
	DW	0FC00H		;CS
	DW	INTRAP		;IP 1C
	DW	0FC00H		;CS
	DW	INTRAP1D 	;IP 1D
	DW	0FC00H		;CS
	DW	INTRAP1E 	;IP 1E
	DW	0FC00H		;CS
	DW	INTRAP1F 	;IP 1F
	DW	0FC00H		;CS
	DW	00000H		;IP 20
	DW	00000H		;CS 
	DW	00000H		;IP 21
	DW	00000H		;CS
	DW	00000H		;IP 22
	DW	00000H		;CS
	DW	00000H		;IP 23
	DW	00000H		;CS
	DW	00000H		;IP 24
	DW	00000H		;CS
	DW	00000H  	;IP 25
	DW	00000H		;CS
	DW	00000H		;IP 26
	DW	00000H		;CS
	DW	00000H		;IP 27
	DW	00000H		;CS
	DW	00000H  	;IP 28
	DW	00000H		;CS
	DW	00000H          ;IP 29
	DW	00000H		;CS
	DW	00000H		;IP 2A
	DW	00000H		;CS
	DW	00000H   	;IP 2B
	DW	00000H		;CS
	DW	00000H  	;IP 2C
	DW	00000H		;CS
	DW	00000H  	;IP 2D
	DW	00000H		;CS
	DW	00000H  	;IP 2E
	DW	00000H		;CS
	DW	00000H  	;IP 2F
	DW	00000H		;CS
	DW	00000H		;IP 30
	DW	00000H		;CS 
	DW	00000H		;IP 31
	DW	00000H		;CS
	DW	00000H		;IP 32
	DW	00000H		;CS
	DW	00000H		;IP 33
	DW	00000H		;CS
	DW	00000H		;IP 34
	DW	00000H		;CS
	DW	00000H  	;IP 35
	DW	00000H		;CS
	DW	00000H		;IP 36
	DW	00000H		;CS
	DW	00000H		;IP 37
	DW	00000H		;CS
	DW	00000H  	;IP 38
	DW	00000H		;CS
	DW	00000H          ;IP 39
	DW	00000H		;CS
	DW	00000H		;IP 3A
	DW	00000H		;CS
	DW	00000H   	;IP 3B
	DW	00000H		;CS
	DW	00000H  	;IP 3C
	DW	00000H		;CS
	DW	00000H  	;IP 3D
	DW	00000H		;CS
	DW	00000H  	;IP 3E
	DW	00000H		;CS
	DW	00000H  	;IP 3F
	DW	00000H		;CS
	DW	HARD_BASE	;IP 40
	DW	0FC00H		;CS
	DW	HARD_BASE  	;IP 41
	DW	0FC00H		;CS
	DB	0780H DUP(0)
;*******************************
; End of Interrupt table.      *
;*******************************


BADMES:	DB	'Non system disk or NO disk in DRIVE A:',0DH,0AH
	DB	'Place system disk in drive A:, press ANY key when ready'
	DB	0DH,0AH,0AH,0FFH
ACCEL:	DB	'Booting DOS...........',0DH,0AH,0FFH
MESBOOT:DB	'286 CPU MEMORY READ/WRITE SOFTWARE, (C) 1987,1988 P.D. Smart',0DH,0AH,0FFH
MESILC:	DB	'COMMAND PASSED IS NOT RECOGNISED',0DH,0AH,0FFH

LTAB1:	DB	0BAH,04H,0CH,0EEH,0EAH,0F0H,03FH,00H,0FCH,00H

RS232_BASE	EQU	0000H  
PRINTER_BASE	EQU	0008H
EQUIP_FLAG  	EQU	0010H
MFG_TST		EQU	0012H
MEMORY_SIZE	EQU	0013H
MFG_ERR_FLAG	EQU	0015H
KB_FLAG		EQU	0017H
KB_FLAG_1	EQU	0018H
ALT_INPUT	EQU	0019H
BUFFER_HEAD	EQU	001AH
BUFFER_TAIL	EQU	001CH
KB_BUFFER	EQU	001EH
INTR_FLAG	EQU	006BH
BIOS_BREAK	EQU	0071H
RESET_FLAG	EQU	0072H
PRINT_TIM_OUT	EQU	0078H
RS232_TIM_OUT	EQU	007CH
BUFFER_START	EQU	0080H
BUFFER_END	EQU	0082H
;
INS_STATE	EQU	80H
CAPS_STATE	EQU	40H
NUM_STATE	EQU	20H
SCROLL_STATE	EQU	10H
ALT_SHIFT	EQU	08H
CTL_SHIFT	EQU	04H
LEFT_SHIFT	EQU	02H
RIGHT_SHIFT	EQU	01H
INS_SHIFT	EQU	80H
CAPS_SHIFT	EQU	40H
NUM_SHIFT	EQU	20H
SCROLL_SHIFT	EQU	10H
HOLD_STATE	EQU	08H
NUM_KEY		EQU	69
SCROLL_KEY	EQU	70
ALT_KEY		EQU	56
CTL_KEY		EQU	29
CAPS_KEY	EQU	58
LEFT_KEY	EQU	42
RIGHT_KEY	EQU	54
INS_KEY		EQU	82
DEL_KEY		EQU	83



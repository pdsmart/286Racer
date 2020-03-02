;****************************************************************************
;** TurboRacer 286 control ROM routines.                                   **
;** ------------------------------------                                   **
;**                                                                        **
;** (C) 1987, 1988 P.D. Smart                                              **
;**                                                                        **
;** This source file contains the coding used to control the TurboRacer    **
;** 286. It's basic structure is as follows:-                              **
;**                                                                        **
;** 16k ROM (8K * 16bit) mapped into addresses 8000:0000 - FFFF:FFFF,      **
;** which is 512K in size. The rom is only used for initialization, and    **
;** is paged out after startup.                                            **
;**                                                                        **
;** Addresses considered within this ROM are FC00:0000 - FC00:3FFF which   **
;** is 16K. Within this 16K allocation, it is subdivided into 4 main       **
;** areas, namely:-                                                        **
;**                                                                        **
;** FC00:0000 -> CPU test code,                                            **
;**              Memory test code,                                         **
;**              Basic initiator code,                                     **
;**                :- Load in new BIOS.                                    **
;**                :- Load in test code.                                   **
;**                :- Execute memory exercise code.                        **
;**                :- Boot up DOS using BIOS in rom.                       **
;**                                                                        **
;** FC00:1000 -> Interrupt vector tables,                                  **
;**              Read/Write messages.                                      **
;**                                                                        **
;** FC00:2000 -> BIOS                                                      **
;**                                                                        **
;** FC00:3FF0 -> RESET boot up code.                                       **
;**                                                                        **
;** This file is assembled using the A86 assembler. To assemble correctly, **
;** invoke A86 at the DOS prompt as follows:-                              **
;**                                                                        **
;** C:\> A86 TURBOROM.ASM STARTUP.ASM MEM.ASM TABLES.ASM BIOS.ASM          **
;**                                                                        **
;**                                                                        **
;****************************************************************************

	ORG	00000H		;FC00:0000









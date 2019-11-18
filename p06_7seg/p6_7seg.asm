;------------------------------------------------
; Kitchen Timer
; P0 - segments
; P1 - digits
;------------------------------------------------

// Time constants
TH0_INIT	EQU 232
DV_T0_INIT	EQU 5
BASIC_TIME	EQU 100 ; "100"  for 	m-ss (time format)
					; "6000" for	h-mm

DSEG	AT	28H
DV_T0:	DS	1
CNT:	DS	1
CNT4:	DS  1	
DATA4:	DS	4
CNT100:	DS	1

BSEG	AT	0H	

CSEG AT 0H
RESET:
	AJMP	INIT_SYSTEM;
ORG 0003H
	AJMP	INT0_ISR
ORG 000BH
	AJMP	T0_ISR
ORG 0013H
	AJMP	INT1_ISR
ORG 001BH
	AJMP	T1_ISR
ORG 0023H
	AJMP	UART_ISR
ORG 002BH
	AJMP	T2_ISR

INIT_SYSTEM:
CLR_MEM:
	MOV		R7,#88;
	MOV		R0,#8
	MOV		A,#0;
CLR_MEM_LP:
	MOV		@R0,A
	INC		R0
	DJNZ	R7,CLR_MEM_LP

INIT_STACK:
	MOV		SP,#127		
	MOV		P0+6,#0FFh
	MOV		P0,#0
	MOV		P1,#1
	MOV		P3,#0FEH
	MOV		DV_T0,#DV_T0_INIT

INIT_TIMER:
	MOV		TH0,#TH0_INIT	
	MOV		TMOD,#11H
	MOV		TCON,#55H
INIT_INT:
	MOV		IE,#10001010B
	MOV 	CNT4,#0
	MOV 	P1,#0FFH
	MOV 	CNT100,#BASIC_TIME
	MOV		R0,#DATA4
// display data table
	MOV 	DATA4,		#0
	MOV 	DATA4+1,	#0
	MOV 	DATA4+2,	#10
	MOV 	DATA4+3,	#9
	
MAIN_LOOP:
	SJMP	MAIN_LOOP
	
T0_ISR:
// save register values
	PUSH	PSW
	PUSH	ACC	
	MOV		TH0,#TH0_INIT
// devide frequency by BASIC_TIME
	MOV 	R1,#CNT100
	DEC 	@R1
	CJNE 	@R1,#1,BREAK1
	MOV 	CNT100,#BASIC_TIME
// minutes	
	MOV		R1,#DATA4
	INC 	@R1
	CJNE 	@R1,#10,BREAK1
	MOV 	@R1,#0
// decimal minutes
	INC 	R1
	INC		@R1
	CJNE 	@R1,#6,BREAK1
	MOV 	@R1,#0
// dash
	INC 	R1
// hours
	INC 	R1
	INC 	@R1
	CJNE 	@R1,#10,BREAK1
	MOV 	@R1,#0

BREAK1:	
	POP		ACC
	POP		PSW
	RETI
	
INT0_ISR:
INT1_ISR:
UART_ISR:
T1_ISR:
	MOV 	TH1,#250
	PUSH	PSW
	PUSH	ACC	
	mov 	DPTR,#DISPLAYS
	MOV		A,CNT4
	CJNE    A,#04H,BREAK
	MOV		CNT4,#0
	MOV		R0,#2BH
	MOV		A,CNT4
BREAK:
	MOVC	A,@A + DPTR
	MOV		P1,A	
	MOV 	A,@R0
	INC 	R0
	MOV 	DPTR,#TO_7SEG
	MOVC	A,@A + DPTR
	MOV		P0,A
	
	INC		CNT4
	POP		ACC
	POP		PSW
	RETI

T2_ISR:
	RETI
	
TO_7SEG:	
	;	0	1	2	3
	;	4	5	6	7
	;	8	9	- 	?
	DB	0xDE, 0x82, 0xEC, 0xE6
	DB	0xB2, 0x76, 0x7E, 0xC2
	DB	0xFE, 0xF6, 0x20, 0xBA

DISPLAYS:
// masks to enable particular displays
	DB	0xfe, 0xfd,0xfb,0xf7

END

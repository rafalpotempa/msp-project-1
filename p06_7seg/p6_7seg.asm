;------------------------------------------------
; Kitchen Timer
; P0 - segments
; P1 - digits
;------------------------------------------------

// Time constants
TH0_INIT	EQU 232
DV_T0_INIT	EQU 5
BASIC_TIME	EQU 100 // "100"  for 	m-ss (time format)
					// "6000" for	h-mm

DSEG	AT	28H
KB_STATE:	DS	1
KB_TMR:		DS	1
KB_PREV:	DS	1
KB_REG:		DS	1

DV_T0:		DS	1
CNT:		DS	1
CNT4:		DS  1	
DATA4:		DS	4
CNT100:		DS	1

BSEG	AT	0H	
RQ_KB:		DBIT 1

CSEG 	AT 	0H
RESET:
	AJMP	INIT_SYSTEM
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
	MOV		R7,#88
	MOV		R0,#8
	MOV		A,#0
CLR_MEM_LP:
	MOV		@R0,A
	INC		R0
	DJNZ	R7,CLR_MEM_LP

INIT_STACK:
	MOV		SP,#127		
	MOV		P0+6,#0FFH
	MOV		P0,#0
	MOV		P1,#1
	MOV		DV_T0,#DV_T0_INIT

INIT_TIMER:
	MOV		TH0,#TH0_INIT	
	MOV		TMOD,#11H
	MOV		TCON,#55H
INIT_INT:
	MOV		IE,#10001010B
	MOV 	CNT4,#0
	MOV 	P1,#0ffh
	MOV 	CNT100,#BASIC_TIME
	MOV		R0,#DATA4
// display data table
	MOV 	DATA4,		#0
	MOV 	DATA4+1,	#0
	MOV 	DATA4+2,	#10
	MOV 	DATA4+3,	#9
	
MAIN_LOOP:
// check for event from keyboard
	JNB		RQ_KB,MAIN_LOOP
	CLR		RQ_KB
	MOV		A,KB_REG
	XRL		A,P1
	MOV		P1,A
	SJMP	MAIN_LOOP
	
KB_INIT:	
	MOV		KB_STATE,#ST_KB_FIRST
	RET

;----------------------------------------------------------
; Parametry sterownika klawiatur
;----------------------------------------------------------

KB_DET_DY	EQU	2; 		Liczba cykli do wykrycia klawisza	
KB_TPM_DY	EQU	200;	Liczba cykli do rozp. auto. powt.
KB_REP_DY	EQU	50;		Liczba cykli okresu auto. powt.
KB_REL_DY	EQU	3;		Liczba cykli do wykrycia zwolnienia klaw.	
KB_REP_MASK	EQU	0FH;	Klawisze powtarzane - maska bitowa	

;----------------------------------------------------------
; Stany automatu sterownika klawiatury
;----------------------------------------------------------
ST_KB_FIRST	EQU	0
ST_KB_NEXT	EQU	1
ST_KB_REP	EQU	2
ST_KB_REL	EQU 3	
	
KB_DRV:	
	MOV		A,P3
	CPL		A		
	MOV		R7,KB_STATE	
KB_FIRST:
	CJNE	R7,#ST_KB_FIRST,KB_NEXT	
	MOV		R6,#8
	MOV		R5,#0
KB_CHK_LP:	
	RL		A
	JNB		ACC.0,KB_CHK_NK
	INC		R5
KB_CHK_NK:	
	DJNZ	R6,KB_CHK_LP
	;Check valid key pattern (only 1-key)
	CJNE	R5,#1,KB_CHK_EX
	MOV		KB_PREV,A
	MOV		KB_TMR,#KB_DET_DY
	MOV		KB_STATE,#ST_KB_NEXT
KB_CHK_EX:	
	RET	
KB_NEXT:
	CJNE	R7,#ST_KB_NEXT,KB_REP
	CJNE	A,KB_PREV, KB_NEXT_REL
	DJNZ	KB_TMR,KB_NEXT_EX
	SETB	RQ_KB
	MOV		KB_REG,KB_PREV
	ANL		A,#KB_REP_MASK
	JZ		KB_NEXT_REL	
KB_NEXT_REP:
	MOV		KB_STATE,#ST_KB_REP
	MOV		KB_TMR,#KB_TPM_DY	
KB_NEXT_EX:		
	RET	
KB_NEXT_REL:	
	MOV		KB_STATE,#ST_KB_REL
	MOV		KB_TMR,#KB_REL_DY
	RET

KB_REP:
	CJNE	R7,#ST_KB_REP,KB_REL
	CJNE	A,KB_PREV,KB_NEXT_REL
	DJNZ	KB_TMR,KB_REP_EX	
	MOV		KB_TMR,#KB_REP_DY
	SETB	RQ_KB
	MOV		KB_REG,KB_PREV
KB_REP_EX:	
	RET

KB_REL:
	CJNE	R7,#ST_KB_REL,KB_ERR
	JZ		KB_REL_CONT
	MOV		KB_TMR,#3
	RET
KB_REL_CONT:	
	DJNZ	KB_TMR,KB_EX
KB_ERR:	
	MOV		KB_STATE,#ST_KB_FIRST	
KB_EX:	
	RET

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
	MOV	R1,#DATA4
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
	MOV 	DPTR,#DISPLAYS
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

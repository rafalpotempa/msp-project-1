;------------------------------------------------
; Wyswietlanie multiplekosowane
; Odswiezanie f(REF) = 80Hz 
; Skanowanie f(SCAN) = 6 x 80 = 480
; 
;------------------------------------------------

DSEG	AT	28H

TH1_INIT	EQU	251
DISP_MAX	EQU	6	
DISP_BUF:	DS	DISP_MAX; 	Bufor wyswietlacza
DISP_PTR:	DS	1;			Wsakznik/licznik wyswietlacza
	
BSEG	AT	0


CSEG	AT	0
	
TO_CNT:
	MOV MY_CNT,#0FFh
	MOV A,MY_CNT
	INC A
	CJNE A,#10,CNT_OK
	CLR A
CNT_OK:
	MOV MY_CNT,A
	MOV DPTR,#TO_SEG
	MOV A,@A + DPTR
	MOV DISP_BUF,A
		
RESET:	
	JMP		INIT
ORG 0003H
	JMP		INT0_ISR
ORG 00BH
	JMP		T0_ISR
ORG 0013H
	JMP		INT1_ISR
ORG 001BH
	JMP		T1_ISR
ORG 0023H
	JMP		UART_ISR
ORG 002BH
	JMP		T2_ISR

INIT:	
	MOV		R7,#120;
	MOV		R0,#8
	MOV		A,#0;
INIT_LP:
	MOV		@R0,A
	INC		R0
	DJNZ	R7,INIT_LP
INIT_STACK:
	MOV		SP,#7FH
	
	;Wylacz wyswietlacz
	MOV		P0,#0
	MOV		P0 + 6, #0FFh
	MOV		P1,#0FFh
	
INIT_DISP_BUF:	
	;Inicjalizacja bufora wysw.
	MOV		DPTR,#TO_7SEG
	MOV		R0,#DISP_BUF + 5
	MOV		R7,#DISP_MAX

INIT_DISP_BUF_LP:
	CLR		A
	MOVC	A,@A + DPTR
	MOV		@R0,A
	INC		DPTR
	DEC		R0
	DJNZ	R7,INIT_DISP_BUF_LP
	
INIT_TIMER:	
	MOV		TH1,#TH1_INIT
;GATE|C/nT|M1|M0
;MODE 0 - 8bit TH + div 5bit  TL
;MODE 1 - 16 bit TH + TL
;MODE 2 - 8 bit TH ld TL
;MODE 3 - 2 x 8bit TL->T0, TH->T1
	MOV		TMOD,#10H
;TF1|TR1|TF0|TR0|IE1|IT1|IE0|IT1
;TFx - Timer OVF INT trigger
;TRx - Timer Run
;IEx - Ext Interrupt detection (Auto CLR after reception)
;ITx - 0 - Level/ 1 - Edge Int triggering
	MOV		TCON,#40H
INIT_INT:
;EA|-|ET2|ES|ET1|EX1|ET0|EX0
;EA - Global Int Enable
;ET - Timer
;ES - Serial
;EX - External
	MOV		IE,#10001000B	
	MOV		P0+6,#0FFH ;Port overdrive		
MAIN_LOOP:
	SJMP	MAIN_LOOP


T1_ISR:
	;Adjust timer to 80Hz -> 1280 cycles only!!!
	MOV		TH1,#TH1_INIT
	;ISR Prolog
	PUSH	PSW
	PUSH	ACC
	MOV		A,R0
	PUSH	ACC	
T1_ISR_BODY:
	;ISR Body
	MOV		P1,#0FFh	
	MOV		A,DISP_PTR
	ADD		A,#DISP_BUF
	MOV		R0,A
	MOV		P0,@R0
	MOV		A,DISP_PTR
	MOV		DPTR,#TO_RING
	MOVC	A,@A + DPTR	
	MOV		P1,A
	MOV		A,DISP_PTR
	INC		A
	CJNE	A,#DISP_MAX,T1_ISR_EX
	CLR		A
T1_ISR_EX:
	;ISR Epilog
	MOV		DISP_PTR,A
	POP		ACC
	MOV		R0,ACC
	POP		ACC
	POP		PSW
	RETI
	
INT0_ISR:
INT1_ISR:
UART_ISR:
T2_ISR:
T0_ISR:
	RETI	

TO_7SEG:	
	DB	0xDE, 0x82, 0xEC, 0xE6
	DB	0xB2, 0x76, 0x7E, 0xC2
	DB	0xFE, 0xF6, 0x1C, 0xBA
	DB	0xF8, 0xFA, 0x20, 0x00
		
TO_RING:		
	DB 0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF

END	
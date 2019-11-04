;------------------------------------------------
; Wyswietlacz 7-segmentowy dekdowanie
; P0 - segmenty
; P1 - cyfry
;------------------------------------------------

; Symboliczne wartosci do inicjalizacji licznikow i dzielnikow
; Latwosc zmiany wartosc
TH0_INIT	EQU	16
DV_T0_INIT	EQU	5

DSEG	AT	28H
DV_T0:	DS	1
CNT:	DS	1

BSEG	AT	0H	

CSEG AT 0H
RESET:
	AJMP	INIT_SYSTEM; Instrukcja skoku w obrebie 2kB sektora
	;Wektory przerwan
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
	MOV		DV_T0,#DV_T0_INIT

INIT_TIMER:
	MOV		TH0,#TH0_INIT	
;GATE|C/nT|M1|M0
;MODE 0 - 8bit TH + div 5bit  TL
;MODE 1 - 16 bit TH + TL
;MODE 2 - 8 bit TH ld TL
;MODE 3 - 2 x 8bit TL->T0, TH->T1
	MOV	TMOD,#11H
;TF1|TR1|TF0|TR0|IE1|IT1|IE0|IT1
;TFx - Timer OVF INT trigger
;TRx - Timer Run
;IEx - Ext Interrupt detection (Auto CLR after reception)
;ITx - 0 - Level/ 1 - Edge Int triggering
	MOV	TCON,#50H
INIT_INT:
;EA|-|ET2|ES|ET1|EX1|ET0|EX0
;EA - Global Int Enable
;ET - Timer
;ES - Serial
;EX - External
	MOV	IE,#10001010B

MAIN_LOOP:
	SJMP	MAIN_LOOP
	
T0_ISR:
	;Zachowujemy rejestry ktore ulegaja zmianie
	PUSH	PSW
	PUSH	ACC	
	MOV		TH0,#TH0_INIT
	;Podzial programowy
	DJNZ	DV_T0,T0_ISR_EX
	MOV		DV_T0,#DV_T0_INIT	
T0_ISR_BODY:	
	MOV		DPTR,#TO_7SEG
	MOV		A,CNT
	INC		A
	ANL		A,#0FH
	MOV		CNT,A
	MOVC	A,@A + DPTR
	MOV		P0,A	
T0_ISR_EX:	
	POP		ACC
	POP		PSW
	RETI

INT0_ISR:
INT1_ISR:
UART_ISR:
T1_ISR:
T2_ISR:
	RETI
	
TO_7SEG:	
	DB	0xDE, 0x82, 0xEC, 0xE6
	DB	0xB2, 0x76, 0x7E, 0xC2
	DB	0xFE, 0xF6, 0x1C, 0xBA
	DB	0xF8, 0xFA, 0x20, 0x00
		

END	

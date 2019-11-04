;--------------------------------------------------------------------
; Sterownik klawiatur
; P3 - Klawisze
; Czestotliwosc probkowania f(samp) = 100Hz
; Implementacja autorepetycji
; Metoda zglosznia nacisniecia klawisza
; rq_kb - flaga zdarzenia (bitowa)
; kb_reg - rejestr klawiatury (zmienna bajtowa)
;--------------------------------------------------------------------

; Symboliczne wartosci do inicjalizacji licznikow i dzielnikow
; Latwosc zmiany wartosc
TH0_INIT	EQU	232
DV_T0_INIT	EQU	25

DSEG	AT	28H
KB_STATE:	DS	1
KB_TMR:		DS	1
KB_PREV:	DS	1
KB_REG:		DS	1

DV_T0:	DS	1
DV_T1:	DS	1

BSEG	AT	0H	
RQ_KB:	DBIT	1

CSEG AT 0H
RESET:
	AJMP	INIT_SYSTEM
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
	MOV		R7,#120;
	MOV		R0,#8
	MOV		A,#0;
CLR_MEM_LP:
	MOV		@R0,A
	INC		R0
	DJNZ	R7,CLR_MEM_LP

INIT_STACK:
	MOV		SP,#7Fh	
	
	MOV		P1,#0FEh
	MOV		P3,#0FEh

INIT_TIMER:
	MOV		TH0,#TH0_INIT	
;GATE|C/nT|M1|M0
;MODE 0 - 8bit TH + div 5bit  TL
;MODE 1 - 16 bit TH + TL
;MODE 2 - 8 bit TH ld TL
;MODE 3 - 2 x 8bit TL->T0, TH->T1
	MOV		TMOD,#01H
;TF1|TR1|TF0|TR0|IE1|IT1|IE0|IT1
;TFx - Timer OVF INT trigger
;TRx - Timer Run
;IEx - Ext Interrupt detection (Auto CLR after reception)
;ITx - 0 - Level/ 1 - Edge Int triggering
	MOV		TCON,#10H
INIT_INT:
;EA|-|ET2|ES|ET1|EX1|ET0|EX0
;EA - Global Int Enable
;ET - Timer
;ES - Serial
;EX - External
	MOV		IE,#10000010B

MAIN_LOOP:
	JNB		RQ_KB,MAIN_LOOP
	;Zdarzenie pochodzace z klawiatury
	CLR		RQ_KB
	MOV		A,KB_REG
	XRL		A,P1
	MOV		P1,A
	; Powrot do petli glownej
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
KB_REP_MASK	EQU	0Fh;	Klawisze powtarzane - maska bitowa	

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
	;Korekta licznika czasomierza
	MOV		TH0,#TH0_INIT	
	PUSH	PSW
	PUSH	ACC
	;Zmiana banku rejestrowego
	SETB	PSW.RS0
T0_ISR_BODY:		
	ACALL	KB_DRV
T0_ISR_EX:			
	; Epilog podprogramu przerwania
	; odtworzenie stanu rejestrow	
	POP		ACC
	POP		PSW
	RETI


INT0_ISR:
INT1_ISR:
UART_ISR:
T1_ISR:
T2_ISR:
	RETI
	
END
	
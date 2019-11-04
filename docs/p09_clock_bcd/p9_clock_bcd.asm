;----------------------------------------------------------
; Zegar czasu rzeczywistego
; P1/P3
; f(CLK) = 7.3728MHz
; f(CORE) = f(CLK)/12 = 614400
; Zalozenie
; f(T0) = 100Hz -> TH0 = 256 - 24 = 232, TL0 = 0
; P3 - Stan zegara (h/m/s) zgodnie z wyborem przez P1
; P1.0 - start
; P1.1 - sec
; P1.2 - min
; P1.3 - hr
; P1.7 - stop
;----------------------------------------------------------
TH0_INIT	EQU	232
;Na potrzeby testu ograniczone do 5 
DV_T0_INIT	EQU	5
;Wartosc normalna 100 (do pracy w systemie)
;DV_T0_INIT	EQU	100
	
DSEG	AT 28h
DV_T0:		DS	1
CLOCK:	
CL_SEC:		DS	1
CL_MIN:		DS	1
CL_HR:		DS	1
CL_SEL:		DS	1
	
BSEG
CL_RUN:		DBIT	1; Clock run flag (stop -> 0)
CL_HC:		DBIT	1; Clock has changed request


CSEG	AT	0
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
	MOV		DV_T0,#DV_T0_INIT

;GATE|C/nT|M1|M0
;MODE 0 - 8bit TH + div 5bit  TL
;MODE 1 - 16 bit TH + TL
;MODE 2 - 8 bit TH ld TL
;MODE 3 - 2 x 8bit TL->T0, TH->T1
	MOV	TMOD,#01H
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
	MOV	IE,#10000010B
	SETB	CL_HC
MAIN_LOOP:
	MOV		A,P1
	CPL		A
	JNB		ACC.0,CL_RUN_END
	SETB	CL_RUN
CL_RUN_END:
	JNB		ACC.7,CL_STOP_END
	CLR		CL_RUN
CL_STOP_END:
	JNB		ACC.1,CL_SEC_END
	MOV		CL_SEL,#0
	SETB	CL_HC
CL_SEC_END:	
	JNB		ACC.2,CL_MIN_END
	MOV		CL_SEL,#1
	SETB	CL_HC
CL_MIN_END:
	JNB		ACC.3,CL_HR_END
	MOV		CL_SEL,#2
	SETB	CL_HC
CL_HR_END:
	JNB		CL_HC,PRINT_END
	CLR		CL_HC
	MOV		A,CL_SEL
PRINT_SEL:	
	CJNE	A,#0,PRINT_SEC_END
	MOV		A, CL_SEC
	SJMP	PRINT_RES
PRINT_SEC_END:	
	CJNE	A,#1,PRINT_MIN_END
	MOV		A,CL_MIN
	SJMP	PRINT_RES
PRINT_MIN_END:	
	CJNE	A,#2,PRINT_HR_END
	MOV		A,CL_HR
	SJMP	PRINT_RES
PRINT_HR_END:	
	SJMP	PRINT_END
PRINT_RES:
	CPL		A
	MOV		P3,A
PRINT_END:
	SJMP	MAIN_LOOP
	
T0_ISR:
	; Prolog podprogramu przerwania
	; zachowanie rejestrow ktore ulegaja modyfikacji
	PUSH	PSW
	PUSH	ACC
	; Zmien aktywny zespol rejestrowy na 1
	; zakladamy ze domyslny roboczy to 0
	; Stos nalezy przeniesc obowiazkowo poza 
	; oba banki rejestow
	SETB	RS0
T0_ISR_BODY:		
	MOV		TH0,#TH0_INIT
	;Programowy dzielnik czestotliwosci
	DJNZ	DV_T0,T0_ISR_EX
	MOV		DV_T0,#DV_T0_INIT
	JNB		CL_RUN,T0_ISR_EX
	MOV		R0,#CLOCK
	ACALL	CLOCK_INC
	SETB	CL_HC
T0_ISR_EX:			
	; Epilog podprogramu przerwania
	; odtworzenie stanu rejestrow
	POP		ACC
	POP		PSW
	RETI	
	
;----------------------------------------------------------
; Niewykorzystywane przerwania na wszelki wypadek RETI
;----------------------------------------------------------
T1_ISR:	
INT0_ISR:
INT1_ISR:
UART_ISR:	
	RETI

;----------------------------------------------------------
; Pdprogram inkrementacji czasu w formacie BCD 
; w zakresie 24H
; R0 - wskaznik do struktury CLOCK
;----------------------------------------------------------
CLOCK_INC:	
	MOV		A,@R0
	ADD		A,#1
	DA		A
	CJNE	A,#60H,CLOCK_EX
	CLR		A
	MOV		@R0,A
	INC		R0
	MOV		A,@R0
	ADD		A,#1
	DA		A
	CJNE	A,#60H,CLOCK_EX
	CLR		A
	MOV		@R0,A
	INC		R0
	MOV		A,@R0
	ADD		A,#1
	DA		A
	CJNE	A,#24H,CLOCK_EX
	CLR		A
CLOCK_EX:
	MOV		@R0,A
	SETB	CL_HC
	RET

END
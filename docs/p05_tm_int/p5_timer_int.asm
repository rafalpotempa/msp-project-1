;----------------------------------------------------------
; Timer w trybie przerwan
; P1/P3
; f(CLK) = 7.3728MHz
; f(CORE) = f(CLK)/12 = 614400
; f(TM) = f(CORE) / CNT
; CNT_MAX = 65536 -> 16 bit overflow
; f(TM) = 10Hz ->
; CNT = 61440 -> TH = 240, TL = 0
; Inicjalizacja/skrocenie cyklu TH = 256 - 240 = 16
; Wazne: Jezeli TL0 = 0 korekcja musi odbyc sie 
; w pierwszych 256 cyklach 
; Dla TL0 <> 0 istotny problem korygowania licznika
; Zalozenie
; f(T0) = 100Hz -> TH0 = 256 - 24 = 232, TL0 = 0
; f(T1) = 10Hz -> TH1 = 256 - 240 = 16, TL1 = 0
;----------------------------------------------------------

; Symboliczne wartosci do inicjalizacji licznikow i dzielnikow
; Latwosc zmiany wartosc
TH0_INIT	EQU	232
DV_T0_INIT	EQU	25
TH1_INIT	EQU	16
DV_T1_INIT	EQU	3

DSEG	AT	28H
DV_T0:	DS	1
DV_T1:	DS	1

BSEG	AT	0H	

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
	MOV		TH1,#TH1_INIT
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
	; Prolog podprogramu przerwania
	; zachowanie rejestrow ktore ulegaja modyfikacji
	PUSH	PSW
	PUSH	ACC
T0_ISR_BODY:		
	MOV		TH0,#TH0_INIT
	;Programowy dzielnik czestotliwosci
	DJNZ	DV_T0,T0_ISR_EX
	MOV		DV_T0,#DV_T0_INIT	
	MOV		A,P1
	RL		A
	MOV		P1,A
T0_ISR_EX:			
	; Epilog podprogramu przerwania
	; odtworzenie stanu rejestrow
	POP		ACC
	POP		PSW
	RETI
	
	
T1_ISR:	
	; Prolog podprogramu przerwania
	; zachowanie rejestrow ktore ulegaja modyfikacji
	PUSH	PSW
	PUSH	ACC
T1_ISR_BODY:	
	; Cialo podprogramu - wlasciwa czesc operacji
	MOV		TH1,#TH1_INIT
	; Programowy dzielnik czestotliwosci
	DJNZ	DV_T1,T1_ISR_EX	
	MOV		TH1,#DV_T1_INIT
	MOV		A,P3
	RL		A
	MOV		P3,A
T1_ISR_EX:			
	; Epilog podprogramu przerwania
	; odtworzenie stanu rejestrow
	POP		ACC
	POP		PSW
	RETI

INT0_ISR:
INT1_ISR:
UART_ISR:
T2_ISR:
	RETI
	
END
	
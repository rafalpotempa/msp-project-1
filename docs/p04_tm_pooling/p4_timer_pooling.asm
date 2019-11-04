;------------------------------------------------
; Timer w trybie przeszukiwania
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
;------------------------------------------------

DSEG	AT	28H
DV_T0:	DS	1
DV_T1:	DS	1
	
BSEG	AT	0H	

CSEG	AT	0h
RESET:	
	MOV		SP,#7Fh
	
INIT_TIMER:
;GATE|COUNTER/nTIMER|M1|M0
;MODE 0 - 8bit TH + div 5bit  TL
;MODE 1 - 16 bit TH + TL
;MODE 2 - 8 bit TH ld TL
;MODE 3 - 2 x 8bit TL->T0, TH->T1
	MOV		TMOD,#11H

;TF1|TR1|TF0|TR0|IE1|IT1|IE0|IT1
;TFx - Timer OVF INT trigger
;TRx - Timer Run
;IEx - Ext Interrupt detection (Auto CLR after reception)
;ITx - 0 - Level/ 1 - Edge Int triggering
	MOV		TCON,#50H
	;Inicjalizacja wstepna licznikow
	MOV		TH0,#232
	MOV		TH1,#16
	;Inicjalizacj dzielnikow programowych
	MOV		DV_T0,#25
	MOV		DV_T1,#3
	;Inicjalizacja portow
	MOV		P1,#0FEH
	MOV		P3,#0FEH	
	
MAIN_LOOP:
	;Sprawdz znacznik - jezeli ustawiony skasuj i skocz
	JBC		TF0,ON_TMR_T0
	JBC		TF1,ON_TMR_T1
	SJMP	MAIN_LOOP
	
ON_TMR_T0:
	;Korekta licznika -> f(T0) = 100Hz
	MOV		TH0,#232
	;Dzielnik wstepny programowy
	DJNZ	DV_T0,MAIN_LOOP
	MOV		DV_T0,#25
	;Akcja
	MOV		A,P1
	RL		A
	MOV		P1,A
	SJMP	MAIN_LOOP
	
ON_TMR_T1:
	;Korekta licznika -> f(T1) = 10Hz
	MOV		TH1,#16
	;Dzielnik wstepny programowy
	DJNZ	DV_T1,MAIN_LOOP
	MOV		DV_T1,#3
	;Akcja
	MOV		A,P3
	RR		A
	MOV		P3,A
	SJMP	MAIN_LOOP
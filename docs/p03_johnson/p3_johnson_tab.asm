;------------------------------------------------
; Licznik Johnsona - zbudowany z wykorzystaniem 
; tablicy przekodowania
; Licznik BIN -> TAB -> Kod Johnsona
; Zmieniajac zawartosci tablicy mozna 
; zaimplementowac dowolny kod (wzorzec)
; np. kod wskaznika 7 seg.
; Opoznienie programowe
; Wskazniki LED P3
;------------------------------------------------
DSEG	AT 28H
CNT:	DS	1


CSEG	AT 0
SYS_INIT:
	; Inicjalizacja stosu - nie korzystamy ze stosu
	; Nalezy bezwglednie pamietac gdy uzywamy 
	; pary CALL - RET 
	; lub przerwan  niejawny -> CALL
	MOV		SP,#7FH
	MOV		CNT,#0H
	; Petla glowna programu
MAIN:	
	
	;Zwieksz lub skoryguj
	MOV		A,CNT
	INC		A
	CJNE	A,#16,CNT_OK
	CLR		A
CNT_OK:	
	MOV		CNT,A

DECODE:
	MOV		A,CNT; Mozna wyeliminowac gdyz A == CNT
	MOV		DPTR,#JOHNSON_TAB	
	MOVC	A,@A + DPTR			
	
	MOV		P3,A
	; Inicjalizacja opoznienia (256 x 514)
	MOV		R7,#0
	ACALL	DELAY
	
	SJMP	MAIN

;------------------------------------------------
; Opoznienie programowe
; R7 - Zakres opznienia -> R7 x 514 cykli 
; cykl -> 12 x CLK
;------------------------------------------------

DELAY:
	MOV		R6,#0
DY_L1:
	DJNZ	R6,DY_L1
	DJNZ	R7,DY_L1
	RET
	
	
JOHNSON_TAB:
	DB	0FFh, 0FEh, 0FCh, 0F8h, 0F0h, 0E0h, 0C0h, 80h, 00h
	DB  01h, 03h, 07h, 0Fh, 1Fh, 3Fh, 7Fh
	
	END


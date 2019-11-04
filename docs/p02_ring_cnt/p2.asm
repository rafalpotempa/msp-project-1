;------------------------------------------------
; Licznik pierscieniwy z krazacym zerem
; Opoznienie programowe
; Wskazniki LED P3
;------------------------------------------------

CSEG	AT 0
SYS_INIT:
	; Inicjalizacja stosu - nie korzystamy ze stosu
	; Nalezy bezwglednie pamietac gdy uzywamy 
	; pary CALL - RET 
	; lub przerwan  niejawny -> CALL
	MOV		SP,#7FH
	MOV		A,#0FEH
	; Petla glowna programu
MAIN:	
	MOV		P3,A	
	RL		A
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
	
	END


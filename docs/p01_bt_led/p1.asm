;----------------------------------------------------------
; Pierwszy program
; Przyciski P1
; Wskazniki LED P3
;----------------------------------------------------------

;----------------------------------------------------------
; CSEG -> Segment programu absolutny
; AT <addr> -> Ulokowany poczawszy od adresu 0
;----------------------------------------------------------
CSEG	AT 0
SYS_INIT:
	; Inicjalizacja stosu - nie korzystamy ze stosu
	; Nalezy bezwglednie pamietac gdy uzywamy 
	; pary CALL - RET 
	; lub przerwan  niejawny -> CALL
	MOV		SP,#7FH
MAIN:
	; Porty dostepne sa jako komorki pamieci 
	; adresowane bezposrednio
	MOV		P3,P1
	SJMP	MAIN
	
	END

* la bateria de pruebas



* --------------------------------------------------------------------> CheckSOL
* 
* 
CheckSOL:
			* Comprobamos que D0 tiene el resultado correcto
			CMP.L	(PRCHAROK),D6			* Comprobamos caracteres que debemos tener.
			BEQ		BIEN					* Saltamos a BIEN.
			JMP 	MAL						* Si no, esta MAL.
BIEN:
*			EOR.L	D0,D0
			BREAK						
			RTS	

MAL:		
*			MOVE.L	#$FFFFFFFF,D0
			BREAK						
			RTS	
			
MAL2:		
*			MOVE.L	#$FFFFFFFF,D0
			BREAK						
			RTS	
* --------------------------------------------------------------------> CheckSOL


* --------------------------------------------------------------------> LEECAR2
* AUX. LEECAR2 (buffer)
*	Objetivo:
*		Leer un caracter del buffer circular designado por el parametro 
*		entrante "buffer"
*
*	Parámetros:
*		buffer
*				Se pasara en A0
*
*	Valor de retorno:
*		D0		
*				- 0 = Todo OK
*		D1		
*				- numero de 0 a 255 caracter del buffer
*
LEECAR2:
	*** NO ES UN BUFFER INTERNO

		* Limpiamos el D1
 		EOR.L		D1,D1							

		* Leemos el ASCII del Buffer pasado en A2
		MOVE.B		(A2),D1		* Extraccion de Ascii en D0. (De 0 a 255 DEC / 0 a FF HEX)
		
		* Aumentamos la dir del Buff pasado
		ADD.L		#$1,A2				
		
		* Ponemos a D0 = 0 para indicar OK
 		EOR.L		D0,D0		
		
		RTS
* --------------------------------------------------------------------> LEECAR2


* --------------------------------------------------------------------> ESCCAR2
* AUX. ESCCAR2 (buffer)
*	Objetivo:
*		Leer un caracter del buffer circular designado por el parametro 
*		entrante "buffer"
*
*	Parametros:
*		buffer
*				Se pasara en A0
*				Nos fijamos en los dos bits menos significativos 
*
*	Valor de retorno:
*		D0		
*				- 0 = Todo OK
*		D1		
*				- numero de 0 a 255 caracter del buffer
*
ESCCAR2:
	*** NO ES UN BUFFER INTERNO
		
		* Guardamos el ASCII pasado en D1 al Buffer pasado
		MOVE.B		D1,(A2)					* Inserccion del Ascii al Buffer seleccionado. (De 0 a 255)
		
		* Aumentamos la dir del Buff pasado.
		ADD.L		#$1,A2				
		
		* Ponemos a D0 = 0 para indicar OK
		EOR.L		D0,D0					
		
		RTS
* --------------------------------------------------------------------> ESCCAR2
		

*** NOTA: abecedario ASCII en Hex
* Letra 	a  b  c  d  e  f  g  h  i  j  k  l  m  n  o  p  q  r  s  t  u  v  w  x  y  z
* Hex 		61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f 70 71 72 73 74 75 76 77 78 79 7a
* 

*** Numeros: en ASCII
* 	dec 	 0   1   2   3   4   5   6   7   8   9
* 	HEX 	30	31	32	33	34	35	36	37	38	39
* 	ASCII 	48  49  50  51  52  53  54  55  56  57



* ----------------------------------------------------------> DATOS PARA SCAN
*
* Funcionamiento:
* SCILETRA: Introduce la letra desde la que quieres que copie ESCCAR [hex].
* SCFLETRA: Introduce la ultima letra que quieres que copie ESCCAR [hex].
* SCBUCSCA:	Numero de veces que quieres que se repita bucle anterior. [dec]
* SCCHARFI: Valor 0 = No quiero RC en mi linea ; 1 = Incluye un 0d al final.
* SCSPEEDR: Introduce la velocidad para las linea. [Mirar valores en tabla]
* SCSDESCR: Valor de descriptor deseado para SCAN. 0 = Linea A; 1 = Linea B.
* SCTAMMAX: Introduce el tamanyo maximo que se debe de leer de la linea incluido 0d.
* SCCHAROK:	Introduce el valor que deberia tener SCAN al final de su ejecucion.

** A continuacion se meten datos de ejemplo, que es vÃ¡lido.

*SCILETRA	EQU		$00000061		* Caracter 'a' [hex].
*SCFLETRA	EQU		$00000074		* Caracter 't' [hex].
*SCBUCSCA	EQU		25			* Repetir bucle 25 veces [dec].
*SCCHARFI	EQU		1			* Quiero que esta prueba contenga al final
								* del bucle un 0d. Indico 1 [dec].
*SCSPEEDR	EQU		%00000000		* Velocidad 50bps [bin].
*SCSDESCR	EQU		$0				* Valor 0 = Linea A [hex}.
*SCTAMMAX	EQU		$4444			* Tamanyo maximo de la linea [hex].
*SCCHAROK	EQU		$000001f5		* Valor que deberia volver SCAN [hex].

dirBUFF 	EQU		$4000           	* El BUFF que a las pruebas

SCILETRA	DC.L		$00000061		* Caracter 'a' [hex].
SCFLETRA	DC.L		$00000074		* Caracter 't' [hex].
SCBUCSCA	DC.L		25			* Repetir bucle 25 veces [dec].
SCCHARFI	DC.L		1			* Quiero que esta prueba contenga al final
								* del bucle un 0d. Indico 1 [dec].
SCLinCFI	DC.L		1			* Quiero que esta prueba contenga al final
								* del bucle un 0d. Indico 1 [dec].
SCNLin		DC.L		0			* Numero de Lineas iguales que se quieren enviar (pr34es_int)
SCSPEEDR	DC.B		%00000000		* Velocidad 50bps [bin].
SCSDESCR	DC.L		$0			* Valor 0 = Linea A [hex}.
SCdir		DC.L		$4e20			* dir de la linea A de SCAN
SCTAMMAX	DC.L		$4444			* Tamanyo maximo de la linea [hex].
SCCHAROK	DC.L		$000001f5		* Valor que deberia volver SCAN [hex].

SCRES2L		DC.L		0			* Guardamos los result de cada linea en SCAN


*** PRINT

PRNLin		DC.L		1			* Numero de Lineas iguales que se quieren enviar (pr34es_int)
PRSDESCR	DC.L		$0			* Valor 0 = Linea A [hex}.
PRTAMMAX    	DC.L		$4444			* Tamanyo maximo de la linea [hex].
PRCHAROK	DC.L		$00000000		* Valor que deberia volver PRINT [hex].

PRRES2L		DC.L		0			* Guardamos los result de cada linea en SCAN

* ----------------------------------------------------------> DATOS PARA SCAN

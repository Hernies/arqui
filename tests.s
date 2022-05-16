* la bateria de pruebas
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
		


prSCes_int:
			MOVE.L	#1,D7					* CONTADOR.
			MOVE.L	(SCFLETRA),D3			* ULTIMO CARACTER A METER.
			
			MOVE.B  (SCSPEEDR),CSRA     		* VELOCIDAD LINEA A.
    		MOVE.B  (SCSPEEDR),CSRB     		* VELOCIDAD LINEA B.


prSCINI:

			MOVE.L	(SCILETRA),D1			* PRIMER CARACTER A METER.
			
	
prSCBUC:		
			MOVE.L	(SCSDESCR),D0			* BUFFER PARA METER DATOS [PUERTO]	
			
			MOVEM.L	A0-A6/D1-D7,-(A7)		* GUARDAMOS REGISTROS EN PILA EXCEPTO D0			
			BSR		ESCCAR					* LLAMAMOS A ESCCAR
			MOVEM.L	(A7)+,A0-A6/D1-D7	    * RESTAURAMOS REGISTROS EXCEPTO D0		

			CMP.L	#$FFFFFFFF,D0			* VERIFICAMOS QUE ESCCAR NO FALLA.
			BEQ		MAL2						* SALTAMOS A ESCFalla.

			CMP.L	D3,D1					* COMPARAMOS SI D1 ES D3 [ULTIMA CARACTER]. 
											* SI LO ES ENTONCES AUMENTO CONT D7.
			BEQ		prSCD7A1				* AUMENTAMOS 1 EN D7	

			ADD.L	#1,D1
			JMP		prSCBUC		

prSCD7A1:	

			CMP.L	(SCBUCSCA),D7			* SI D7 ES REPETICION DEL BUCLE. FIN.
			BEQ		prSCSUM0

			ADD.L	#1,D7
			JMP		prSCINI

prSCSUM0:
		
			CMPI.L	#0,(SCCHARFI)		* Si hay un 0, entonces NO anadiremos 0d al final.
			BEQ		prSCSCAN				* Por lo tanto SCAN deberia salir con D0=0.

			* Si hay un 1 e SCCHARFI, entonces si hay que aÃ±adirlo y se hace un ESCCAR con 0d.

			MOVE.L	#$0000000d,D1			* METEMOS EL SALTO DE LINEA
			MOVEM.L	A0-A6/D1-D7,-(A7)		* GUARDAMOS REGISTROS EN PILA EXCEPTO D0			
			BSR		ESCCAR					* LLAMAMOS A ESCCAR CON D0.
			MOVEM.L	(A7)+,A0-A6/D1-D7	    * RESTAURAMOS REGISTROS EXCEPTO D0		

			CMP.L	#$FFFFFFFF,D0			* VERIFICAMOS QUE ESCCAR NO FALLA.
			BEQ		MAL2						* SALTAMOS A ESCFalla.
			
prSCSCAN:
            

			MOVE.L	(SCSDESCR),D0			* Descriptor
			MOVE.L	(SCCHAROK),D1			* Tamanyo

			MOVE.W 	D1,-(A7)				* Parametro TamaÃ±o para Scan
			MOVE.W 	D0,-(A7)				* Parametro Descriptor para Scan
			MOVE.L 	#dirBUFF,-(A7)			* Parametro Buffer para Scan

			BSR 	SCAN
	
		
		*** Saltamos a comprobar la solución
			* Pasamos en D6 el contador de los corracteres.
			BSR 	CheckSOL
			
			* Salimos
			RTS

pr26es_int:
			MOVE.L	#200,(SCBUCSCA)			* 199 bucles
			MOVE.L	#$00000030,(SCILETRA)	* empezamos en Hex 30 = numero 0 dec
			MOVE.L	#$00000039,(SCFLETRA)	* terminamos en Hex 39 = numero 9 dec

			MOVE.L	#%00000000,(SCSPEEDR)	* Velocidad = 50 bps. (No tenemso la de 5 BPS=40bps)

			MOVE.L	#2001,(SCCHAROK)	* El valor de terminacion correcto

			MOVE.L	#0,(SCCHARFI)
			
			BSR		prSCes_int
			
			RTS


BUFFER:  DS.B 2100 * Buffer para lectura y escritura de caracteres
PARDIR:  DC.L 0 * Direcci´on que se pasa como par´ametro
PARTAM:  DC.W 0 * Tama~no que se pasa como par´ametro
CONTC:   DC.W 0 * Contador de caracteres a imprimir
DESA:    EQU 0 * Descriptor l´ınea A
DESB:    EQU 1 * Descriptor l´ınea B
TAMBS:   EQU 30 * Tama~no de bloque para SCAN
TAMBP:   EQU 7 * Tama~no de bloque para PRINT


* Manejadores de excepciones
INICIO: MOVE.L #BUS_ERROR,8 * Bus error handler
        MOVE.L #ADDRESS_ER,12 * Address error handler
        MOVE.L #ILLEGAL_IN,16 * Illegal instruction handler
        MOVE.L #PRIV_VIOLT,32 * Privilege violation handler
        MOVE.L #ILLEGAL_IN,40 * Illegal instruction handler
        MOVE.L #ILLEGAL_IN,44 * Illegal instruction handler
        BSR INIT
        MOVE.W #$2000,SR * Permite interrupciones

BUCPR:  MOVE.W #TAMBS,PARTAM * Inicializa par´ametro de tama~no
        MOVE.L #BUFFER,PARDIR * Par´ametro BUFFER = comienzo del buffer
* Descriptor incorrecto
PRUEBA1:MOVE.W PARTAM,-(A7)     * Tama~no de bloque
        MOVE.W #3,-(A7)         * Descriptor no valido
        MOVE.L PARDIR,-(A7)     * Direcci´on de lectura
        BSR SCAN                * Llamamos a scan 
* Tamaño = 0 con descriptor correcto
PRUEBA2:MOVE.W #0,-(A7)     * Tama~no de bloque
        MOVE.W #1,-(A7)         * Linea B
        MOVE.L PARDIR,-(A7)     * Direcci´on de lectura
        BSR SCAN                * Llamamos a scan

******************************************************
*       NO METER EN MEMORIA
* Prueba para SCAN de introducir caracteres
* introduce 20 caracteres: 0123456789 (2 veces) + 0d
PRUEBA3:MOVE.W #$20,-(A7)     * Tama~no de bloque
        MOVE.W #0,-(A7)         * Linea A
        MOVE.L PARDIR,-(A7)     * Direcci´on de lectura
        BSR pr26es_int              
        BREAK
******************************************************
* PRINT TESTS 
BUCPR:  MOVE.W #TAMBS,PARTAM * Inicializa par´ametro de tama~no
        MOVE.L #BUFFER,PARDIR * Par´ametro BUFFER = comienzo del buffer
* Descriptor incorrecto
PRUEBA1:MOVE.W #0,-(A7)     * Tama~no de bloque
        MOVE.W #3,-(A7)         * Descriptor no valido
        MOVE.L PARDIR,-(A7)     * Direcci´on de lectura
        BSR PRINT                * Llamamos a scan 
* Tamaño = 0 con descriptor correcto
PRUEBA2:MOVE.W #0,-(A7)     * Tama~no de bloque
        MOVE.W #1,-(A7)         * Linea B
        MOVE.L PARDIR,-(A7)     * Direcci´on de lectura
        BSR PRINT                * Llamamos a scan
SALIR:  BRA BUCPR



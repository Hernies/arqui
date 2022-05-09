* Calvo Aguiar, Hernan. Num mat:190090
* Ayuso Exposito, Alejandro. Num mat:190238
*
******************************************************************
*		PROCEDIMIENTOS DE FORMATEO
*	Las etiquetas que nombran a una subrutina no se tabulan	
*
*	Toda etiqueta dentro de una subrutina se tabula una vez
*
*	Toda etiqueta fuera de una subrutina NO SE TABULA
*
*	Definiciones se tabulan 1 vez
*
*	Codigo dentro de subrutinas se tabula 2 veces
*
*	
*	Los comentarios de subrutinas se tabula una vez a partir de 
*	la linea mas larga y tienen un espacio despues del asterisco
*
*	O, estan a ras con el codigo (misma tabulacion).
*
*	Tambien pueden no tener un espacio del asterisco a modo de titulo
*
*
*	Codigo comentado no tiene espacio despues del asterisco
*	
*	Los dobles asteriscos son notas de los alumnos a si mismos, no son para comunicar informacion al corrector
*	dicho esto, se intentara eliminar todas las anotaciones de los alumnos.
*
******************************************************************

**************************ESCRIBIRCIO DEL PROGRAMA*************

* ESCRIBIRcializa el SP y el PC
**************************
        ORG     $0
        DC.L    $8000           * Pila
        DC.L	INICIO         * PC

        ORG     $400
        

		*DEFESCRIBIRCION EQUIVALENCIAS 

MR1A	EQU		$effc01       * de modo A (escritura)
MR2A	EQU		$effc01       * de modo A (2 escritura)
SRA		EQU		$effc03       * de estado A (lectura)
CSRA	EQU		$effc03       * de seleccion de reloj A (escritura)
CRA		EQU		$effc05       * de control A (escritura)
TBA		EQU		$effc07       * buffer transmision A (escritura)
RBA		EQU		$effc07       * buffer recepcion A  (lectura)
ACR		EQU		$effc09	      * de control auxiliar
IMR		EQU		$effc0B       * de mascara de interrupcion A (escritura)
ISR		EQU		$effc0B       * de estado de interrupcion A (lectura)

MR1B	EQU		$effc11       * de modo B (escritura)
MR2B	EQU		$effc11       * de modo B (2 escritura)
CRB		EQU		$effc15	      * de control A (escritura)
TBB		EQU		$effc17       * buffer transmision B (escritura)
RBB		EQU		$effc17       * buffer recepcion B (lectura)
SRB		EQU		$effc13       * de estado B (lectura)
CSRB	EQU		$effc13       * de seleccion de reloj B (escritura)

IVR		EQU		$effc19		  * de vector de interrupción
IMR		EQU		$effc0b		  * de máscara de interrupción (escritura)
ISR		EQU		$effc0b		  * de estado de interrupción (lectura)

CR		EQU		$0D	      	  * Carriage Return
LF		EQU		$0A	     	  * Line Feed
FLAGT	EQU		2	     	  * Flag de transmisión
FLAGR   EQU     0	     	  * Flag de recepción
*************************************************************************************

		*DEFESCRIBIRCION DE CONSTANTES PERTINENTES A BUFFERS
		*A/B+(S)END/(R)ECIEVE_(ESCRIBIR)CIO/(FIN)AL/(LEER)POINTER




		* LEER ES NUESTRO PUNTERO DE LEER
		* ESCRIBIR ES NUESTRO PUNTERO DE ESCRIBIR
		* FIN ES NUESTO PUNTERO DE  TAMANO DE BUFER
		TAMANO_BUF:		EQU		2000

AR:		DS.B	TAMANO_BUF				* Buffer de recepcion de A
AS:		DS.B	TAMANO_BUF				* Buffer de transmision de A
BR:		DS.B	TAMANO_BUF				* Buffer de recepcion de B
BS:		DS.B	TAMANO_BUF				* Buffer de transmision de B

AS_LEER:		DC.L	0	
AS_ESCRIBIR: 	DC.L	0
AS_FIN:			DC.L	0
AS_FLG:			DC.L	0				* FLAG TRANSMISION A

AR_LEER:		DC.L	0
AR_ESCRIBIR:	DC.L	0
AR_FIN:			DC.L	0
AR_FLG:			DC.L	0				* FLAG RECEPCION A

BS_LEER:		DC.L	0
BS_ESCRIBIR:	DC.L	0
BS_FIN:			DC.L	0
BS_FLG:			DC.L	0				* FLAG TRANSMISION B

BR_LEER:		DC.L	0
BR_ESCRIBIR:	DC.L	0
BR_FIN:			DC.L	0
BR_FLG:			DC.L	0				* FLAG RECEPCION B

CPY_IMR:		DS.B	2
FLAG_TBA:		DS.B	1
FLAG_TBB:		DS.B	1
LAG_LEER:		DS.B	1

	
**************************** INIT *************************************************************
INIT:   MOVE.B			#%00010000,CRA      * ReESCRIBIRcia el puntero MR1
        MOVE.B			#%00010000,CRB		* ReESCRIBIRcia el puntero MR2
        
        MOVE.B			#%00000011,MR1A     * 8 bits por caracter.
        MOVE.B			#%00000011,MR1B		* 8 bits por caracter.
        
        MOVE.B			#%00000000,MR2A     * Eco desactivado en A.
        MOVE.B			#%00000000,MR2B		* Eco desactivado en B.
        
        MOVE.B			#%11001100,CSRA     * Velocidad = 38400 bp.
        MOVE.B			#%11001100,CSRB     * Velocidad = 38400 bp.
        
        MOVE.B			#%00000101,CRA      * Transmision y recepcion activados.
        MOVE.B			#%00000101,CRB      * Transmision y recepcion activados.
        
        MOVE.B			#%00000000,ACR      * Velocidad = 38400 bps.
        
        MOVE.B			#$040,IVR			* Vector interrupcion 40
		MOVE.B			#%00100010,CPY_IMR	* El copy de IMR habilita las interrupciones de A y B
		MOVE.B			CPY_IMR,IMR
		MOVE.L			#RTI,$100

		MOVE.B			#0,FLAG_TBA			* Flag de TBA a 0 
		MOVE.B			#0,FLAG_TBB			* Flag de TBB a 0

		MOVE.W			#AR,AR_LEER 				* Inicializamos ptr de lectura de: ar
		MOVE.W			#BR,BR_LEER 				* br
		MOVE.W			#AS,AS_LEER					* as
		MOVE.W			#BS,BS_LEER	 				* bs

		MOVE.W			#AR,AR_ESCRIBIR 			* Inicializamos ptr de escritura de: ar
		MOVE.W			#BR,BR_ESCRIBIR 			* br
		MOVE.W			#AS,AS_ESCRIBIR				* as
		MOVE.W			#BS,BS_ESCRIBIR	 			* bs

		MOVE.W  		#0,AR_FLG					* FLAGS DE RECEPCION
		MOVE.W  		#0,BR_FLG
		MOVE.W  		#0,AS_FLG					* FLAGS DE RECEPCION
		MOVE.W  		#0,BS_FLG
		RTS

		
**************************** FIN INIT ***********************************************************

**************************** LEECAR *************************************************************
LEECAR:
		* PARA AREC (0)
		CLR			D3				*D3 a 0
		CMP.B 		D0,D3			*Hacemos a altura de byte porque sabemos que tanto D0 como D1 solo tienen info relevante en el primer byte
		BEQ			AREC
		* PARA BREC (1)
		ADD.B		#1,D3			*D1 a 1
		CMP.B 		D3,D0 
		BEQ			BREC
		* PARA ASND (2)
		ADD.B		#1,D3			*D1 a 2
		CMP.B 		D3,D0 
		BEQ			ASND
		* PARA BSND (3)
		ADD.B		#1,D3			*D1 a 3
		CMP.B 		D3,D0 
		BEQ			BSND
		* Si no salta ningun BEQ, la subrutina no deberia hacer nada, solo saltar al fin
		JMP			L_FIN			
	
	AREC:	
		MOVE.L  		#AR,A1					* cargo LEER, ESCRIBIR y EL PUNTERO
		MOVE.L  		#AR_LEER,A2
		MOVE.L  		#AR_ESCRIBIR,A4
		MOVE.L			#AR_FLG,D4
		BSR 			LEER
		JMP 			L_FIN
	BREC:
		MOVE.L  		#BR,A1					* cargo LEER, ESCRIBIR y EL PUNTERO
		MOVE.L  		#BR_LEER,A2
		MOVE.L  		#BR_ESCRIBIR,A4
		MOVE.L			#BR_FLG,D4
		BSR 			LEER
		JMP 			L_FIN
	ASND:
		MOVE.L  		#AS,A1					* cargo LEER, ESCRIBIR y EL PUNTERO
		MOVE.L  		#AS_LEER,A2
		MOVE.L  		#AS_ESCRIBIR,A4
		MOVE.L			#AS_FLG,D4
		BSR 			LEER
		JMP 			L_FIN
	BSND:
		MOVE.L  		#BS,A1					* cargo LEER, ESCRIBIR y EL PUNTERO
		MOVE.L  		#BS_LEER,A2
		MOVE.L  		#BS_ESCRIBIR,A4
		MOVE.L			#BS_FLG,D4
		BSR 			LEER
		JMP 			L_FIN
	L_FIN:
		RTS
			*********** AUXILIAR DE LEECAR **********
                    * Realiza la parte general de las operaciones de lectura
	LEER:
		
		CLR 			D0 					* D0 A 0
		
		MOVE.W			(A4),A5				* Guardamos el puntero en A5
		MOVE.W          (A2),A3				* Guardamos el puntero en A3
		CMP 			A3,A5				* SI, BUFFER VACIO	
		BEQ				L_VACIO				
	L_FULL:
		MOVE.B 			(A3),D0				* PTR DE ESCRITURA => D0
		MOVE.W			D2,D3				
		ADD.W			#1999,D3			* D4 == FIN BUFFER
		* LECTURA == FIN_BUFFER??
		CMP 			A3,D3				* SI, PTR VA AL PRINCIPIO // NO, PTR++
		BEQ     		FIN_LAUX	    	
		ADD.W			#1,(A2)				
		RTS

	L_VACIO:
		MOVE.L			D4,A1
		* FLG == 1??
		CMP				(A1),D0				* NO, LEER 
		BNE				L_FULL				
		MOVE.L			#$FFFFFFFF,D0
		RTS

	FIN_LAUX:
		MOVE.L			D4,A5
		MOVE.W 			#0,(A5)				* FLAG A 0
		MOVE.W			D2,(A2)				* PTR A POS ORIGINAL
		RTS

	
**************************** FIN LEECAR **********************************************************

**************************** ESCCAR **************************************************************
ESCCAR:
		
		*Compruebo lo que vale buffer (D0)
		
		* PARA AREC (0)
		CLR				D3				*D3 a 0
		CMP.B 			D3,D0			*Hacemos a altura de byte porque sabemos que tanto D0 como D1 solo tienen info relevante en el primer byte
		BEQ				E_AREC
		
		* PARA BREC (1)
		ADD.B			#1,D3			*D3 a 1
		CMP.B 			D3,D0 
		BEQ				E_BREC
		
		* PARA ASND (2)
		ADD.B			#1,D3			*D3 a 2
		CMP.B 			D3,D0 
		BEQ				E_ASND
		
		* PARA BSND (3)
		ADD.B			#1,D3			*D3 a 3
		CMP.B 			D3,D0 
		BEQ				E_BSND
		
		* Si no salta ningun BEQ, la subrutina no deberia hacer nada, solo saltar al fin
		JMP			E_FIN	
	
	E_AREC:	
		MOVE.L  		#AR,A1					* cargo LEER, ESCRIBIR y EL PUNTERO
		MOVE.L  		#AR_LEER,A2
		MOVE.L  		#AR_ESCRIBIR,A4
		MOVE.L			#AR_FLG,D4
		BSR 			ESCRIBIR
		JMP 			E_FIN
	E_BREC:
		MOVE.L  		#BR,A1					* cargo LEER, ESCRIBIR y EL PUNTERO
		MOVE.L  		#BR_LEER,A2
		MOVE.L  		#BR_ESCRIBIR,A4
		MOVE.L			#BR_FLG,D4
		BSR 			ESCRIBIR
		JMP 			E_FIN
	E_ASND:
		MOVE.L  		#AS,A1					* cargo LEER, ESCRIBIR y EL PUNTERO
		MOVE.L  		#AS_LEER,A2
		MOVE.L  		#AS_ESCRIBIR,A4
		MOVE.L			#AS_FLG,D4
		BSR 			ESCRIBIR
		JMP 			E_FIN
	E_BSND:
		MOVE.L  		#BS,A1					* cargo LEER, ESCRIBIR y EL PUNTERO
		MOVE.L  		#BS_LEER,A2
		MOVE.L  		#BS_ESCRIBIR,A4
		MOVE.L			#BS_FLG,D4
		BSR 			ESCRIBIR
		JMP 			E_FIN
	E_FIN:
		RTS
		        *********** AUXILIAR DE ESCCAR **********
                * Realiza la parte general de las operaciones de lectura
	ESCRIBIR:
		
		CLR				D3
		MOVE.W			(A4),A5				* Guardamos el puntero en A5
		MOVE.W          (A2),A3				* Guardamos el puntero en A3
		CLR 			D0 					* D0 A 0
		
		* PTR DE ESCRITURA == PTR LECTURA?? 
		CMP 			A3,A5				* COMPROBAMOS CPRE
		BEQ				CMP_CPRE

	E_VACIO:
		MOVE.B 			D1,(A5)				* PTR DE ESCRITURA => D1
		MOVE.W			A1,D3				
		ADD.W			#1999,D3			* D4 == FIN BUFFER
		* LECTURA == FIN_BUFFER??
		CMP 			A5,D3				* SI, PTR VA AL PRINCIPIO // NO, PTR++
		BEQ     		FIN_EAUX	    	
		ADD.W			#1,(A4)		
		CLR 			D0					* D0 a 0
		RTS

	CMP_CPRE:
		MOVE.L			D4,A2				
		*FLG == 0?? 
		CMP 			(A2),D0				* SI, ESCRIBIMOS // NO, DO = #$FFFFFFFF
		BEQ 			E_VACIO
		MOVE.L			#$FFFFFFFF,D0
	
	FIN_EAUX:
		MOVE.L			D4,A5
		MOVE.W 			#1,(A5)				* FLAG A 0
		MOVE.W			A1,(A4)				* PTR A POS ORIGINAL
		RTS

	
**************************** FIN ESCCAR ***********************************************************		

********************************** SCAN ***********************************************************
SCAN:


		LINK			A6,#0
	* LIMPIO D1, D2, D3
		CLR         	D0                  * Limpio D0 para return
		CLR				D1					* Limpio D1 para descriptor			
		CLR				D2					* Limpio D2 para tamano
		CLR				D3					* Contador a 0 
		CLR				D4					* Limpio D4
		MOVE.W			8(A7),A1			* Buffer en A1 (marco de pila + buffer)
		MOVE.W			12(A7),D1			* Descriptor
		MOVE.W			14(A7),D2			* Tamano a D2 (marco de pila + buffer + descriptor + tamano )
	
	* COMPARACIONES PARA SABER SI ES A O B Y TAMAÑO
		CMP				#0,D2				* Comparo si tamaño <= 0
		BLE				SC_FIN
		
		CMP				#0,D1				* Si es 0 escritura es en A
		BEQ				A_SCAN
		
		CMP				#1,D1				* Si es 1 escritura es en B
		BEQ				B_SCAN

	ERROR_SC: 
		MOVE.L			#$ffffffff,D0		* D0 = -1
		JMP				SC_FIN
	
	A_SCAN:
		MOVE.L			#0,D0				* Es 2 por el ESCCAR q si recibe 2 se va a buffer interno de transaminsion
		JMP				BUCLE_S
	B_SCAN:
		MOVE.L			#1,D0
		JMP				BUCLE_S
		
		JMP 			ERROR_SC			* Por si el descriptor esta mal
	*BUCLE DE SCAN:
	BUCLE_S:
		*MOVE.W 		-40(A7),D2			* Saco D2 de pila?????	pa q sirve este PA NA// ESTO KK
		CMP.L			D3,D2				* Si contador == tamano, hemos terminado
		BEQ				SC_FIN
		MOVE.L 			D3,-(A7)			* PUSH(D3)-> contador
		MOVE.L 			A1,-(A7)			* PUSH(A1)-> dir buffer
		MOVE.L 			D2,-(A7)			* PUSH(D2)-> tamano
		MOVE.B			#0,D0				* Ponemos a LEECAR el buffer para operar
		BSR 			LEECAR				* Llamada a LEECAR
		MOVE.L 			(A7)+,D2		    * POP(D2) <- tamano
		MOVE.L 			(A7)+,A1		    * POP(A1) <- dir buffer
		MOVE.L 			(A7)+,D3		    * POP(D3) <- conatdor 
		
		MOVE.L 			#$ffffffff,D6		* D6 -> -1
		CMP.L			D0,D6 				*Esccar dice q el buffer esta vacio, hemos acabado		
		BEQ				SC_FIN
		MOVE.L			D0,(A1)+			* cuestionable!!!!!!!!
		ADD.L			#1,D3				* Contador + 1
		JMP				BUCLE_S
				
	SC_FIN:
		MOVE.L 			D3,D0
		UNLK			A6	
		RTS  
****************************** FIN SCAN ***********************************************************

********************************** PRINT **********************************************************
PRINT:
		LINK			A6,#0
		
	* LIMPIO D1, D2, D3
		CLR 			D0
		CLR				D1				* Limpio D1 para descriptor			
		CLR				D2				* Limpio D2 para tamano
		CLR				D3				* Contador a 0 
		CLR				D4				* Limpio D4 para gaurdar el SR
		MOVE.L 			8(A7),A1 		* Buffer en A1 (marco de pila + buffer)	
		MOVE.W			12(A7),D1		* D1 <- Descriptor
		MOVE.W			14(A6),D2		* Tamano a D2 (marco de pila + buffer + descriptor + tamano )
	
	* COMPARACIONES PARA SABER SI ES A O B
	
		CMP.W			#0,D1			* Si es 0 escritura es en A
		BEQ				A_PRINT
		CMP.W			#1,D1			* Si es 1 escritura es en B
		BEQ				B_PRINT
		
	ERROR_PR: 
		MOVE.L			#$ffffffff,D0	* D0 = -1
		JMP				P_FIN 
	
	A_PRINT:
		MOVE.L			#2,D0			* Es 2 por el ESCCAR q si recibe 2 se va a buffer interno de transaminsion
		BRA				BUCLE_P
	B_PRINT:
		MOVE.L			#3,D0
		JMP				BUCLE_P
		
	*BUCLE DE PRINT:
	BUCLE_P:
		CMP.L			D3,D2			* Si tamano == contador, hemos terminado
		BEQ				P_TER
		 
		MOVE.B			(A1),D5				* Avanzo el buffer y guardo el dato en D5
		MOVE.L 			D3,-(A7)			* PUSH(D3)-> contador
		MOVE.L 			A1,-(A7)			* PUSH(A1)-> dir buffer
		MOVE.L 			D2,-(A7)			* PUSH(D2)-> tamano
		BSR				ESCCAR
		MOVE.L 			(A7)+,D2		    * POP(D2) <- tamano
		MOVE.L 			(A7)+,A1		    * POP(A1) <- dir buffer
		MOVE.L 			(A7)+,D3		    * POP(D3) <- conatdor
		ADD.L			#1,A1
		
		MOVE.L 			#$ffffffff,D6
		CMP.L			D6,D0 			*Esccar dice q el buffer esta lleno, hemos acabado		
		BEQ 			P_TER
		ADD.L			#1,D3			* Contador + 1
		JMP				BUCLE_P
		
	P_TER:
		CLR				D4
		MOVE.W 			SR,D4 				* SR -> D4
		MOVE.W   		#$2700,SR 			* Inhibicion de interrupciones

		* COMPROBACIONES
		CMP.W			#0,D1			* Compruebo si estamos en A
		BEQ				A_SET
		
		CMP.W			#1,D1			* Compruebo si estamos en B
		BEQ				B_SET
	
	A_SET:							
		OR.B 			#%00000001,CPY_IMR
		MOVE.B 			CPY_IMR,IMR			* Interrupciones en A 
		MOVE.W 			D4,SR				* SR a valor original	
		JMP 			P_FIN
	B_SET:							
		OR.B 			#%00010000,CPY_IMR
		MOVE.B 			CPY_IMR,IMR			* Interrupciones en A 
		MOVE.W 			D4,SR				* SR a valor original	
			
	P_FIN:
		MOVE.L 			D3,D0
		UNLK			A6
		RTS	 
****************************** FIN PRINT *************************************************************

****************************** RTI *************************************************************


RTI:
		MOVEM.L D0-D7,-(A7) 				* Guardamos todos nuestros registros en la pila
		MOVEM.L A0-A7,-(A7) 
		
	COMP_PREV:
		CLR 		D2
		CLR 		D3
		MOVE.B		CPY_IMR,D2			* Guardo en D2 el valor de la copia del IMR (mascara)
		MOVE.B 		ISR,D3				* Guardo en D3 el valor del ISR (Estado de Interrupción)
		AND.B 		D3,D2				* Aplico la mascara

		BTST		#0,D2
		BNE			RTI_TRANS_A			**TRANSMISION -> LEECAR

		BTST		#1,D2
		BNE			RTI_RECEP_A			** RECEPCION -> ESCCAR

		BTST		#4,D2
		BNE			RTI_TR_B			**TRANSMISION -> LEECAR
		
		BTST		#5,D2
		BNE			RTI_RC_B			** RECEPCION -> ESCCAR

	FIN_RTI:
		MOVEM.L (A7)+,A0-A7				* Restauro los registros
		MOVEM.L (A7)+,D0-D7
		RTE
	
	RTI_TRANS_A:
		*CMP.B   	#0,FLAG_TBA      	* Se transmite caracter
		CLR 		D0
		MOVE.B		#%00000010,D0
		BSR			LEECAR				* Llamamos a leecar
		MOVE.L 		#$ffffffff,D4
		CMP.L		D4,D0				* Buffer interno vacio??
		BEQ			RTA_VACIO			
		MOVE.B		D0,TBA				* mete el caracter 
		JMP     	COMP_PREV	
	RTA_VACIO:
        CLR 		D1
		CLR 		D3
		MOVE.B 		CPY_IMR,D1
		MOVE.B		#%11111110,D3
		AND.B 		D3,D1
		MOVE.B		D1,CPY_IMR
		MOVE.B		CPY_IMR,IMR
        JMP     	COMP_PREV		
		
	RTI_RECEP_A:
		CLR			D0					* Pongo D0 a 0 -> ESCCAR uso buffer recepcion A
		CLR 		D1					* Pongo D1 a 0
		MOVE.B		RBA,D1				* Guardo los datos del buffer de recepcion de A en D1
		MOVE.L		#%00000000,D0
		BSR			ESCCAR				* LLamadita a ESCCAR
		JMP			COMP_PREV			* D0 != -1 a comparar otra vez

	RTI_TR_B:
		*CMP.B   	#0,FLAG_TBA      	* Se transmite caracter
		CLR 		D0
		MOVE.B		#%00000011,D0
		BSR			LEECAR				* Llamamos a leecar
		MOVE.L 		#$ffffffff,D4
		CMP.L		D4,D0				* Buffer interno vacio??
		BEQ			RTB_VACIO			
		MOVE.B		D0,TBB				* mete el caracter 
		JMP     	COMP_PREV	
	RTB_VACIO:
        CLR 		D1
		CLR 		D3
		MOVE.B 		CPY_IMR,D1
		MOVE.B		#%11101111,D3
		AND.B 		D3,D1
		MOVE.B		D1,CPY_IMR
		MOVE.B		CPY_IMR,IMR
        JMP     	COMP_PREV	

	RTI_RC_B:
		CLR			D0					* Pongo D0 a 0 -> ESCCAR uso buffer recepcion A
		CLR 		D1					* Pongo D1 a 0
		MOVE.B		RBB,D1				* Guardo los datos del buffer de recepcion de A en D1
		MOVE.L		#%00000001,D0
		BSR			ESCCAR				* LLamadita a ESCCAR		
		JMP			COMP_PREV			* D0 != -1 a comparar otra vez

****************************** FIN RTI ************************************************************
**************************** PROGRAMA PRINCIPAL ********************************
* Tester para casos limite de las subrutinas. Instala manejadores de excepcion
BUFFER: 	DS.B 6400 					* Buffer para lectura y escritura de caracteres
PARDIR: 	DC.L 0 						* Direccion que se pasa como parametro
PARTAM: 	DC.W 0 						* Tamano que se pasa como parametro
CONTC:  	DC.W 6000 						* Contador de caracteres a imprimir
DESA:   	EQU 0 						* Descriptor linea A
DESB:   	EQU 1 						* Descriptor linea B
TAMBP:  	EQU 1500 					* Tamano de bloque para PRINT	

* Manejadores de excepciones
INICIO: 	
            MOVE.L  #BUS_ERROR,8 		* Bus error handler
			MOVE.L  #ADDRESS_ER,12 		* Address error handler
			MOVE.L  #ILLEGAL_IN,16 		* Illegal instruction handler
			MOVE.L  #PRIV_VIOLT,32 		* Privilege violation handler
			MOVE.L  #ILLEGAL_IN,40 		* Illegal instruction handler
			MOVE.L  #ILLEGAL_IN,44 		* Illegal instruction handler
			
			BSR INIT
			MOVE.W #$2000,SR 			* Permite interrupciones

            MOVE.L #BUFFER,A0           * A0 = Dir del bufer
            MOVE.L #600,D0              * Contador
BLOQUE:      
            
            MOVE.B #$31,(A0)+
            MOVE.B #$32,(A0)+
            MOVE.B #$33,(A0)+
            MOVE.B #$34,(A0)+
            MOVE.B #$35,(A0)+
            MOVE.B #$36,(A0)+
            MOVE.B #$37,(A0)+
            MOVE.B #$38,(A0)+
            MOVE.B #$39,(A0)+
            MOVE.B #$30,(A0)+
            SUB.L  #1,D0
            CMP.L  #0,D0
            BNE    BLOQUE

            NOP
		
BUCPR:  	
            MOVE.W #TAMBP,PARTAM 		* Inicializa parametro de tamano
			MOVE.L #BUFFER,PARDIR 		* Parametro BUFFER = comienzo del buffer

B1:   	    MOVE.W PARTAM,-(A7) 		* Tamano de escritura
			MOVE.W #DESA,-(A7) 			
			MOVE.L PARDIR,-(A7) 		* Direccion de escritura
			BSR PRINT
			ADD.L #8,A7					* Restablece la pila
			ADD.L D0,PARDIR 			* Calcula la nueva direccion del buffer
			SUB.W D0,CONTC 				* Actualiza el contador de caracteres

B2:   	    MOVE.W PARTAM,-(A7) 		* Tamano de escritura
			MOVE.W #DESB,-(A7) 			
			MOVE.L PARDIR,-(A7) 		* Direccion de escritura
			BSR PRINT
			ADD.L #8,A7					* Restablece la pila
			ADD.L D0,PARDIR 			* Calcula la nueva direccion del buffer
			SUB.W D0,CONTC 				* Actualiza el contador de caracteres
        
B3:   	    MOVE.W PARTAM,-(A7) 		* Tamano de escritura
			MOVE.W #DESA,-(A7) 			
			MOVE.L PARDIR,-(A7) 		* Direccion de escritura
			BSR PRINT
			ADD.L #8,A7					* Restablece la pila
			ADD.L D0,PARDIR 			* Calcula la nueva direccion del buffer
			SUB.W D0,CONTC 				* Actualiza el contador de caracteres

B4:   	    MOVE.W PARTAM,-(A7) 		* Tamano de escritura
			MOVE.W #DESB,-(A7) 			
			MOVE.L PARDIR,-(A7) 		* Direccion de escritura
			BSR PRINT
			ADD.L #8,A7					* Restablece la pila
			ADD.L D0,PARDIR 			* Calcula la nueva direccion del buffer
			SUB.W D0,CONTC 				* Actualiza el contador de caracteres

SALIR:  	BRA BUCPR
BUS_ERROR:  BREAK 						* Bus error handler
			NOP
ADDRESS_ER: BREAK 						* Address error handler
			NOP
ILLEGAL_IN: BREAK 						* Illegal instruction handler
			NOP
PRIV_VIOLT: BREAK 						* Privilege violation handler
			NOP 
*inicializar SP y PC
**************************
        ORG $0
        DC.L $8000
        DC.L INICIO

        ORG $400

**************************

MR1A   EQU $effc01       * modo A (escritura)
MR2A   EQU $effc01       * modo A (2 escritura)
SRA    EQU $effc03       * estado A (lectura)
CSRA   EQU $effc03       * seleccion de reloj A (escritura)
CRA    EQU $effc05       * control A (escritura)
TBA    EQU $effc07       * buffer transmision A (escritura)
RBA    EQU $effc07       * buffer recepcion A  (lectura)
ACR    EQU $effc09	 * control auxiliar
IMR    EQU $effc0B       * mascara de interrupcion A (escritura)
ISR    EQU $effc0B       * estado de interrupcion A (lectura)

MR1B   EQU $effc11       * modo B (escritura)
MR2B   EQU $effc11       * modo B (2 escritura)
CRB    EQU $effc15	 * control A (escritura)
TBB    EQU $effc17       * buffer transmision B (escritura)
RBB    EQU $effc17       * buffer recepcion B (lectura)
SRB    EQU $effc13       * estado B (lectura)
CSRB   EQU $effc13       * seleccion de reloj B (escritura)

IVR    EQU $effc19       * Registro vector de interrupcion

CR     EQU $0D	         * Carriage Return
LF     EQU $0A	         * Line Feed
FLAGT  EQU 2	         * Flag de transmision
FLAGR  EQU 0	         * Flag de recepcion
TAMBUF EQU 2001

IMRDUP  DC.B      0     * Duplicado (legible) del IM

INCLUDE bib_aux.s


**************************** INIT ****************************************************
INIT:

** Inicializar linea A
                        MOVE.B    #%00010000,CRA      * Dar acceso a reg. modo 1
                        MOVE.B    #%00000011,MR1A     * 8 bits por caracter
                        MOVE.B    #%00000000,MR2A     * Desactivar el eco
                        MOVE.B    #%00000101,CRA      * Modo full duplex
                        MOVE.B    #%11001100,CSRA     * Velocidad = 38400 bps tx y rx

** Inicializar linea B
                        MOVE.B    #%00010000,CRB      * Dar acceso a reg. modo 1
                        MOVE.B    #%00000011,MR1B     * 8 bits por caracter
                        MOVE.B    #%00000000,MR2B     * Desactivar el eco
                        MOVE.B    #%00000101,CRB      * Modo full duplex
                        MOVE.B    #%11001100,CSRB     * Velocidad = 38400 bps tx y rx

** Inicializaciones globales
                        MOVE.B    #%00000000,ACR      * Conjunto de veloc. 1
                        MOVE.B    #$40,IVR            * Vector int 0x40
                        MOVE.B    #%000100010,IMR     * Activar bits 1 y 5 para interr. RX
                        MOVE.B    #%000100010,IMRDUP  * Actualiza copia del IMR
                        MOVE.L    #RTI,$100           * Insertar dir RTI en el primer vector de interrupciones

                        BSR      INI_BUFS

** Inicializacion de los contadores a cero y reseteo de A0
                        MOVE.L    #0,D0
                        MOVE.L    #0,A0
                        RTS
*************************** FIN INI **************************************************

*************************** SCAN *****************************************************
** Lee los caracteres que entran y los copia al buffer indicado
* Llama a LEECAR
* 
SCAN:
                        LINK A6,#-44
                        *MOVEM.L	A0-A5/D1-D5,-(A6)
                        MOVE.L          D1,-4(A6)
                        MOVE.L          D2,-8(A6)
                        MOVE.L          D3,-12(A6)
                        MOVE.L          D4,-16(A6)
                        MOVE.L          D5,-20(A6)
                        MOVE.L          A0,-24(A6)
                        MOVE.L          A1,-28(A6)
                        MOVE.L          A2,-32(A6)
                        MOVE.L          A3,-36(A6)
                        MOVE.L          A4,-40(A6)
                        MOVE.L          A5,-44(A6)
                        ** Reset de parámetros
                        MOVE.L         #0,D0          * * RETURN (0XFFFFFFFF O NUMERO DE CARACTERES ACEPTADOS PARA LECTURA)
                        MOVE.L         #0,D1
                        MOVE.L         #0,D2
                        MOVE.L         #0,D3
                        MOVE.L         #0,D4
                        MOVE.L         #0,D5
                        MOVE.L      8(A6),A1        * DIR BUFFER A A1
                        MOVE.W      12(A6),D1       * DESCRIPTOR A D1
                        MOVE.W      14(A6),D2       * TAMAÑO A D2
                        MOVE.W      D1,D5           * HAGO UNA COPIA DE D1 PARA USARLA DESPUES 
                        MOVE.L      #$FFFFFFFF,D4   * D4 = -1 para casos y comprobaciones

                        **SELECCION DE BUFFER**
                        CMP.W       #0,D1
                        BEQ         SA              *LEER POR A 
                        CMP.W       #1,D1
                        BEQ         SB              *ESCRIBIR POR B

                        **ERROR EN CARACTER**
                        MOVE.L       D4,D0       * Devuelvo -1 para tamaño=0/
                        BRA         FN_SCER

                        **LECTURA**
        
        SA:             CMP.L       D2,D3           * Tamanyo = contador? Cubre tamanyo=0
                        BEQ         FN_SCN          * Si -> fin
                        MOVE.L      #0,D0           * Aseguramos que D0 selecciona el buffer correcto
                        BSR         LEECAR          * D0=0 luego llamo a leecar sin problemas
                        CMP.L       D0,D4           * Buffer vacio? (D0=FFFFFFFF?) 
                        BEQ         FN_SCN          * Si -> fin
                        MOVE.B      D0,(A1)+        * mover a buffer incrementando puntero
                        ADD.L       #1,D3           * incremento contador de caracteres leidos
                        BRA         SA

        SB:             CMP.L       D2,D3           * SI SE HA LEIDO TODO -> FIN
                        BEQ         FN_SCN          * Si -> fin
                        MOVE.L      #1,D0           * Aseguramos que D0 selecciona el buffer correcto
                        BSR         LEECAR          * D0=0 luego llamo a leecar sin problemas
                        CMP.L       D0,D4           * Buffer vacio? (D0=FFFFFFFF?)
                        BEQ         FN_SCN          * Si -> fin
                        MOVE.B      D0,(A1)+        * mover a buffer incrementando puntero
                        ADD.L       #1,D3           * incremento contador de caracteres leidos
                        BRA         SB 

                        **FIN SCAN** 

        FN_SCN:         MOVE.L          D3,D0                * D0<-contador de caracteres leidos 
        FN_SCER:        MOVE.L          -4(A6),D1
                        MOVE.L          -8(A6),D2
                        MOVE.L          -12(A6),D3
                        MOVE.L          -16(A6),D4
                        MOVE.L          -20(A6),D5
                        MOVE.L          -24(A6),A0
                        MOVE.L          -28(A6),A1
                        MOVE.L          -32(A6),A2 
                        MOVE.L          -36(A6),A3 
                        MOVE.L          -40(A6),A4 
                        MOVE.L          -44(A6),A5
                        *MOVEM.L	(A6)+,A0-A5/D1-D5                    
                        UNLK A6
                        RTS

*************************** FIN SCAN *************************************************
*************************** PRINT ****************************************************
** Escribe en un bufer interno (de tamaño 2000) de manera no bloqueante (acaba cuando termina de escribir Buffer)
* Llama a ESCCAR
* Devuelve el numero de caracteres copiados en D0
* puntero de pila tiene que estar igual que al principio (LINK u ULINK)
                    ****** RECUERDA ****** 
                        *   An -> REGISTRO DE DIRECCIONES 
                        *   Dn -> REGISTRO DE DATOS
PRINT:
                        LINK A6,#-48
                        *MOVEM.L	A0-A5/D1-D5,-(A6)
                        MOVE.L          D1,-4(A6)
                        MOVE.L          D2,-8(A6)
                        MOVE.L          D3,-12(A6)
                        MOVE.L          D4,-16(A6)
                        MOVE.L          D5,-20(A6)
                        MOVE.L          D6,-24(A6)
                        MOVE.L          A0,-28(A6)
                        MOVE.L          A1,-32(A6)
                        MOVE.L          A2,-36(A6)
                        MOVE.L          A3,-40(A6)
                        MOVE.L          A4,-44(A6)
                        MOVE.L          A5,-48(A6)
                * LIMPIO D1, D2, D3
                        MOVE.L         #0,D0
                        MOVE.L         #0,D1				* Limpio D1 para descriptor			
                        MOVE.L         #0,D2				* Limpio D2 para tamano
                        MOVE.L         #0,D3				* Contador a 0 
                        MOVE.L         #0,D4				* Limpio D4 para guardar el SR
                        MOVE.L         #0,D5
                        MOVE.L         #0,D6
                        MOVE.L 			8(A6),A1 		* Buffer en A1 
                        MOVE.W			12(A6),D1		* D1 <- Descriptor
                        MOVE.W			14(A6),D2		* Tamano a D2 
                
                * COMPARACIONES PARA SABER SI ES A O B
                
                        CMP.W			#0,D1			* Si es 0 escritura es en A
                        BEQ			BUCLE_PA
                        CMP.W			#1,D1			* Si es 1 escritura es en B
                        BEQ		        BUCLE_PB
                        
        ERROR_PR: 
                        MOVE.L			#$ffffffff,D0	* D0 = -1
                        JMP			P_FER           * saltamos a la salida de error 
                
                        
                *BUCLE DE PRINT:
        
        BUCLE_PA:
                        CMP.L			D3,D2			* Si tamano == contador, hemos terminado
                        BEQ			A_SET
                        
                        MOVE.B                  (A1)+,D1                * Avanzo el buffer y guardo el dato en D5
                        MOVE.L                  #2,D0
                        BSR			ESCCAR
                        MOVE.L 			#$ffffffff,D6
                        CMP.L			D6,D0 			*Esccar dice q el buffer esta lleno, hemos acabado		
                        BEQ 			A_SET
                        ADD.L			#1,D3			* Contador + 1
                        JMP			BUCLE_PA

        BUCLE_PB:
                        CMP.L			D3,D2			* Si tamano == contador, hemos terminado
                        BEQ			B_SET
                        
                        MOVE.B                  (A1)+,D1                * Avanzo el buffer y guardo el dato en D5
                        MOVE.L                  #3,D0
                        BSR			ESCCAR
                        MOVE.L 			#$ffffffff,D6
                        CMP.L			D6,D0 			*Esccar dice q el buffer esta lleno, hemos acabado		
                        BEQ 			B_SET
                        ADD.L			#1,D3			* Contador + 1
                        JMP			BUCLE_PB
        
                
        A_SET:		CMP.L                   #0,D3
                        BEQ                     P_FIN
                        MOVE.B                  IMRDUP,D4          					
                        OR.B 			#%00000001,D4
                        MOVE.B 			D4,IMRDUP			* Interrupciones en A 
                        MOVE.B                  D4,IMR
                        BRA 			P_FIN

        B_SET:		CMP.L                   #0,D3
                        BEQ                     P_FIN  
                        MOVE.B                  IMRDUP,D4          					
                        OR.B 			#%00010000,D4
                        MOVE.B 			D4,IMRDUP			* Interrupciones en B
                        MOVE.B                  D4,IMR
                                 
        P_FIN:
                        MOVE.L 			D3,D0
                        *MOVEM.L	                (A6)+,A0-A5/D1-D5                    
        P_FER:          MOVE.L          -4(A6),D1
                        MOVE.L          -8(A6),D2
                        MOVE.L          -12(A6),D3
                        MOVE.L          -16(A6),D4
                        MOVE.L          -20(A6),D5
                        MOVE.L          -24(A6),D6
                        MOVE.L          -28(A6),A0
                        MOVE.L          -32(A6),A1
                        MOVE.L          -36(A6),A2 
                        MOVE.L          -40(A6),A3 
                        MOVE.L          -44(A6),A4 
                        MOVE.L          -48(A6),A5
                        UNLK A6
                        RTS
*************************** FIN PRINT *****************************************************
*************************** RTI ****************************************************
*DUDA: Porque el SR cambia de 2400-2404 aparentemente aleatoriamente?
* Primero comprobar ISR (estado de interrupción) -> 4 bits 1 para cada
* Luego comprobar la línea, el modo (lectura o escritura)? -> me lo dice el 
*       Si es recepción (lectura) entonces comprobar que FIFO !empty() 

*TODO Comprobar BUFFERS CORRECTOS
*TODO sentido aplicar mascara? RTA/RTB_VACIO
*TODO CLR vs MOVE.L #0,DX

RTI:    LINK A6,#-44
        *MOVEM.L	A0-A5/D0-D4,-(A6)

        MOVE.L          D0,-4(A6)
        MOVE.L          D1,-8(A6)
        MOVE.L          D2,-12(A6)
        MOVE.L          D3,-16(A6)
        MOVE.L          D4,-20(A6)
        MOVE.L          A0,-24(A6)
        MOVE.L          A1,-28(A6)
        MOVE.L          A2,-32(A6)
        MOVE.L          A3,-36(A6)
        MOVE.L          A4,-40(A6)
        MOVE.L          A5,-44(A6)


        * switch (IVR) {case 1:... , ...}

       	COMP_PREV:      CLR 		D2
                        CLR 		D3
        RTI_COMP:       MOVE.B		IMRDUP,D2		* Guardo en D2 el valor de la copia del IMR (mascara)
                        MOVE.B 		ISR,D3  		* Guardo en D3 el valor del ISR (Estado de Interrupción)
                        AND.B 		D2,D3			* Aplico la mascara

                       BTST		#0,D3
                        BNE		RTI_TRANS_A		**TRANSMISION -> LEECAR

                        BTST		#1,D3
                        BNE		RTI_RECEP_A		** RECEPCION -> ESCCAR

                        BTST		#4,D3
                        BNE		RTI_TR_B		**TRANSMISION -> LEECAR
                        
                        BTST		#5,D3
                        BNE		RTI_RC_B		** RECEPCION -> ESCCAR

        FIN_RTI:        MOVE.L          -4(A6),D0 
                        MOVE.L          -8(A6),D1
                        MOVE.L          -12(A6),D2
                        MOVE.L          -16(A6),D3
                        MOVE.L          -20(A6),D4
                        MOVE.L          -24(A6),A0
                        MOVE.L          -28(A6),A1
                        MOVE.L          -32(A6),A2 
                        MOVE.L          -36(A6),A3 
                        MOVE.L          -40(A6),A4 
                        MOVE.L          -44(A6),A5
                        *MOVEM.L	(A6)+,A0-A5/D0-D4               * si no hay interrupciones salimos de la RTI            
                        UNLK A6
                        RTE

        RTI_TRANS_A:
                        *CMP.B   	#0,FLAG_TBA      	* Se transmite caracter
                        CLR 		D0
                        MOVE.B		#2,D0
                        BSR		LEECAR			* Llamamos a leecar
                        MOVE.L 		#$ffffffff,D4
                        CMP.L		D4,D0			* Buffer interno vacio??
                        BEQ		RTA_VACIO			
                        MOVE.B		D0,TBA			* mete el caracter 
                        JMP     	RTI_COMP	
	RTA_VACIO:
                        CLR 		D1
                        CLR 		D3
                        MOVE.B 		IMRDUP,D1
                        MOVE.B		#%11111110,D3
                        AND.B 		D3,D1                   * porque aplicamos máscara?
                        MOVE.B		D1,IMRDUP
                        MOVE.B		IMRDUP,IMR
                        JMP     	RTI_COMP		
		
	RTI_RECEP_A:
                        MOVE.L		#0,D0			* Pongo D0 a 0 -> ESCCAR uso buffer recepcion A
                        MOVE.L		#0,D1			* Pongo D1 a 0
                        MOVE.B		RBA,D1			* Guardo los datos del buffer de recepcion de A en D1
                        BSR		ESCCAR			* LLamada a ESCCAR 
                        JMP		RTI_COMP		     

	RTI_TR_B:
                        *CMP.B   	#0,FLAG_TBA      	* Se transmite caracter
                        CLR 		D0
                        MOVE.B		#3,D0
                        BSR             LEECAR			* Llamamos a leecar
                        MOVE.L 		#$ffffffff,D4
                        CMP.L		D4,D0			* Buffer interno vacio??
                        BEQ		RTB_VACIO			
                        MOVE.B		D0,TBB			* mete el caracter 
                        JMP     	RTI_COMP	
	RTB_VACIO:
                        CLR 		D1
                        CLR 		D3
                        MOVE.B 		IMRDUP,D1
                        MOVE.B		#%11101111,D3
                        AND.B 		D3,D1
                        MOVE.B		D1,IMRDUP
                        MOVE.B		IMRDUP,IMR
                        JMP     	RTI_COMP	

	RTI_RC_B:
                        CLR		D0			* Pongo D0 a 0 -> ESCCAR uso buffer recepcion A
                        CLR 		D1			* Pongo D1 a 0
                        MOVE.B		RBB,D1			* Guardo los datos del buffer de recepcion de A en D1
                        MOVE.L		#1,D0                   * 
                        BSR		ESCCAR			* LLamadita a ESCCAR		
                        JMP		RTI_COMP			* D0 != -1 a comparar otra vez

*************************** FIN RTI ****************************************************
BUFFER:  DS.B 2100 * Buffer para lectura y escritura de caracteres
PARDIR:  DC.L 0 * Direcci´on que se pasa como par´ametro
PARDIR2: DC.L 0 * Direcci´on que se pasa como par´ametro
PARTAM:  DC.W 0 * Tama~no que se pasa como par´ametro
CONTC:   DC.W 0 * Contador de caracteres a imprimir
DESA:    EQU 0 * Descriptor l´ınea A
DESB:    EQU 1 * Descriptor l´ınea B
TAMBS:   EQU 1 * Tama~no de bloque para SCAN
TAMBP:   EQU 1 * Tama~no de bloque para PRINT


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

OTRAL:  MOVE.W PARTAM,-(A7) * Tama~no de bloque
        MOVE.W #DESB,-(A7) * Puerto A
        MOVE.L PARDIR,-(A7) * Direcci´on de lectura

ESPL:   BSR SCAN
        ADD.L #8,A7 * Restablece la pila
        ADD.L D0,PARDIR * Calcula la nueva direcci´on de lectura
        SUB.W D0,PARTAM * Actualiza el n´umero de caracteres le´ıdos
        BNE OTRAL * Si no se han le´ıdo todas los caracteres
        * del bloque se vuelve a leer
        MOVE.W #TAMBS,CONTC * Inicializa contador de caracteres a imprimir
        MOVE.L #BUFFER,PARDIR * Par´ametro BUFFER = comienzo del buffer

OTRAE:  MOVE.W #TAMBP,PARTAM * Tama~no de escritura = Tama~no de bloque

ESPE:   MOVE.W PARTAM,-(A7) * Tama~no de escritura
        MOVE.W #DESA,-(A7) * Puerto B
        MOVE.L PARDIR,-(A7) * Direcci´on de escritura
        BSR PRINT
        ADD.L #8,A7 * Restablece la pila
        ADD.L D0,PARDIR * Calcula la nueva direcci´on del buffer
        SUB.W D0,CONTC * Actualiza el contador de caracteres
        BEQ SALIR * Si no quedan caracteres se acaba
        SUB.W D0,PARTAM * Actualiza el tama~no de escritura
        BNE ESPE * Si no se ha escrito todo el bloque se insiste
        CMP.W #TAMBP,CONTC * Si el no de caracteres que quedan es menor que
        * el tama~no establecido se imprime ese n´umero
        BHI OTRAE * Siguiente bloque
        MOVE.W CONTC,PARTAM
        BRA ESPE * Siguiente bloque

        
SALIR:  BRA BUCPR
BUS_ERROR: BREAK * Bus error handler
        NOP
ADDRESS_ER: BREAK * Address error handler
        NOP
ILLEGAL_IN: BREAK * Illegal instruction handler
        NOP
PRIV_VIOLT: BREAK * Privilege violation handler
        NOP

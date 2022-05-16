

** Proyecto de Arquitectura **
            ORG     $0
            DC.L    $8000               * Pila
            DC.L    MAIN                * PC
SENTINEL:   DS.L    1                   * Sentinel, para que en la traza se pueda ver mejor
                                        *   los comienzos de subrutinas...
** Declarar los buferes y variables globales necesarias para el codigo
            

* V1.0 Feb. 2022
* V1.1 24/02/2022. Alineamiento esccar
* V1.2 14/03/2022. Devoluci�n valor correcto de D0 en ESCCAR
* V1.3 03/05/2022. Se ponen a 0 los 30 bits m�s sign de D0 en LEECAR y ESCCAR
            ORG $400 
** Definicion de equivalencias *****************************************************
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

IMRDUP  DC.B      0     * Duplicado (legible) del IM              *
************************************************************************************

SCAN_A	EQU	0
SCAN_B	EQU	1
PRNT_A	EQU	2
PRNT_B	EQU	3

TAMBUF	EQU	2001

* Buffer de Scan A
BSCAN_A		DC.L	BSC_A	* Puntero de extracci�n 
		DC.L	BSC_A	* Puntero de inserci�n
BSC_A		DS.B	TAMBUF	* BUFFER DE 2001 BYTES

* Buffer de Scan B
BSCAN_B		DC.L	BSC_B	* Puntero de extracci�n 
		DC.L	BSC_B	* Puntero de inserci�n
BSC_B		DS.B	TAMBUF	* BUFFER DE 2001 BYTES

* Buffer de Print A
BPRNT_A		DC.L	BPR_A	* Puntero de extracci�n 
		DC.L	BPR_A	* Puntero de inserci�n
BPR_A		DS.B	TAMBUF	* BUFFER DE 2001 BYTES

* Buffer de Print B
BPRNT_B		DC.L	BPR_B	* Puntero de extracci�n 
		DC.L	BPR_B	* Puntero de inserci�n
BPR_B		DS.B	TAMBUF	* BUFFER DE 2001 BYTES

		DC.W 1


*************************** ESCCAR *********************************************************

ESCCAR:
        MOVEM.L A0-A4/D2,-(A7)       * Guarda todos los registros en la pila

	AND.L   #3,D0
	CMP.L	#SCAN_A,D0
	BNE	ESCB
	MOVE.L	#BSCAN_A,A0
	BRA	CONTESC
ESCB:   CMP.L   #SCAN_B,D0
        BNE     EPRA
        MOVE.L  #BSCAN_B,A0
        BRA     CONTESC
EPRA:   CMP.L   #PRNT_A,D0
        BNE     EPRB
        MOVE.L  #BPRNT_A,A0
        BRA     CONTESC
EPRB: 	MOVE.L  #BPRNT_B,A0

CONTESC: EOR.L D0,D0		* A0 contiene la direcci�n del puntero de extracci�n
	MOVE.L	(A0),A1		* A1 contiene el puntero de extracci�n
	MOVE.L	4(A0),A2	* A2 contiene el puntero de inserci�n 
	MOVE.L	A0,A3
	ADD.L	#8,A3		* A3 contiene el comienzo del buffer 
	MOVE.L	A3,D2
	ADD.L	#TAMBUF,D2
	MOVE.L	D2,A4		* A4 contiene el final del buffer (1 m�s all�)

	MOVE.B	D1,(A2)+		* Inserta el caracter
	CMP.L	A2,A4		* Si son iguales  ha llegado al final del buffer
	BNE	ACPUNE
	MOVE.L	A3,A2		* Se pone el puntero de inserci�n al comienzo del buffer
ACPUNE: CMP.L	A1,A2		* Si son iguales se ha llenado el buffer
	BEQ	LLENO
	MOVE.L	A2,4(A0)	* Actualiza el puntero de inserci�n
	BRA	FINEB
LLENO:	MOVE.L	#-1,D0		* Se devuelve un -1 en D0 
FINEB:	MOVEM.L       (A7)+,A0-A4/D2 *Restauramos los registros
	RTS

*************************** FIN ESCCAR *****************************************************

*************************** LEECAR *********************************************************

LEECAR:
        MOVEM.L A0-A4/D2,-(A7)       * Guarda todos los registros en la pila

	AND.L   #3,D0
	CMP.L	#SCAN_A,D0
	BNE	LSCB
	MOVE.L	#BSCAN_A,A0
	BRA	CONTLEE
LSCB:   CMP.L   #SCAN_B,D0
        BNE     LPRA
        MOVE.L  #BSCAN_B,A0
        BRA     CONTLEE
LPRA:   CMP.L   #PRNT_A,D0
        BNE     LPRB
        MOVE.L  #BPRNT_A,A0
        BRA     CONTLEE
LPRB: 	MOVE.L  #BPRNT_B,A0

CONTLEE:				* A0 contiene la direcci�n del puntero de extracci�n
	MOVE.L	(A0),A1		* A1 contiene el puntero de extracci�n
	MOVE.L	4(A0),A2	* A2 contiene el puntero de inserci�n 
	MOVE.L	A0,A3
	ADD.L	#8,A3		* A3 contiene el comienzo del buffer 
        MOVE.L  A3,D2
        ADD.L   #TAMBUF,D2
        MOVE.L  D2,A4           * A4 contiene el final del buffer (1 m�s all�)

	CMP.L	A1,A2		* Si son iguales, el buffer est� vac�o
	BNE	NOVAC
	MOVE.L	#-1,D0
	BRA	SALLB

NOVAC:	MOVE.B	(A1)+,D0		* Extrae el caracter
	CMP.L	A1,A4		* Si son iguales  ha llegado al final del buffer
	BNE	ACPUNL
	MOVE.L	A3,A1		* Se pone el puntero de extracci�n al comienzo del buffer
ACPUNL:	MOVE.L	A1,(A0)		* Actualiza el puntero de extracci�n

SALLB:	MOVEM.L (A7)+,A0-A4/D2 *Restauramos los registros
	RTS

*************************** FIN LEECAR *****************************************************

*************************** INI_BUFS *********************************************************

INI_BUFS:
	MOVE.L	#BSC_A,BSCAN_A		* Inicia el puntero de extracci�n
	MOVE.L	#BSC_A,BSCAN_A+4	* Inicia el puntero de inserci�n
	MOVE.L	#BSC_B,BSCAN_B		* Inicia el puntero de extracci�n
	MOVE.L	#BSC_B,BSCAN_B+4	* Inicia el puntero de inserci�n
	MOVE.L	#BPR_A,BPRNT_A		* Inicia el puntero de extracci�n
	MOVE.L	#BPR_A,BPRNT_A+4	* Inicia el puntero de inserci�n
	MOVE.L	#BPR_B,BPRNT_B		* Inicia el puntero de extracci�n
	MOVE.L	#BPR_B,BPRNT_B+4	* Inicia el puntero de inserci�n
	
        RTS

*************************** FIN INI_BUFS *****************************************************
**** INIT ****

** A0: Linea de transmision A(0) o B(1)
** A1: Buffer de recepcion(0)[R] o Buffer de transmision(1)[W]

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
                        OR.B 			#%00000001,IMRDUP
                        MOVE.B 			IMRDUP,IMR			* Interrupciones en A 
                        MOVE.B                  D4,IMRDUP
                        BRA 			P_FIN

        B_SET:		CMP.L                   #0,D3
                        BEQ                     P_FIN  
                        MOVE.B                  IMRDUP,D4          					
                        OR.B 			#%00010000,IMRDUP
                        MOVE.B 			IMRDUP,IMR			* Interrupciones en B
                        MOVE.B                  D4,IMRDUP
                                 
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
                        MOVE.B		IMRDUP,D2		* Guardo en D2 el valor de la copia del IMR (mascara)
                        MOVE.B 		ISR,D3  		* Guardo en D3 el valor del ISR (Estado de Interrupción)
                        AND.B 		D3,D2			* Aplico la mascara

                        BTST		#0,D2
                        BNE		RTI_TRANS_A		**TRANSMISION -> LEECAR

                        BTST		#1,D2
                        BNE		RTI_RECEP_A		** RECEPCION -> ESCCAR

                        BTST		#4,D2
                        BNE		RTI_TR_B		**TRANSMISION -> LEECAR
                        
                        BTST		#5,D2
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
                        MOVE.B		#%00000010,D0
                        BSR		LEECAR			* Llamamos a leecar
                        MOVE.L 		#$ffffffff,D4
                        CMP.L		D4,D0			* Buffer interno vacio??
                        BEQ		RTA_VACIO			
                        MOVE.B		D0,TBA			* mete el caracter 
                        JMP     	FIN_RTI	
	RTA_VACIO:
                        CLR 		D1
                        CLR 		D3
                        MOVE.B 		IMRDUP,D1
                        MOVE.B		#%11111110,D3
                        AND.B 		D3,D1                   * porque aplicamos máscara?
                        MOVE.B		D1,IMRDUP
                        MOVE.B		IMRDUP,IMR
                        JMP     	FIN_RTI		
		
	RTI_RECEP_A:
                        CLR		D0			* Pongo D0 a 0 -> ESCCAR uso buffer recepcion A
                        CLR 		D1			* Pongo D1 a 0
                        MOVE.B		RBA,D1			* Guardo los datos del buffer de recepcion de A en D1
                        BSR		ESCCAR			* LLamada a ESCCAR
                        JMP		FIN_RTI		        * D0 != -1 a comparar otra vez

	RTI_TR_B:
                        *CMP.B   	#0,FLAG_TBA      	* Se transmite caracter
                        CLR 		D0
                        MOVE.B		#%00000011,D0
                        BSR             LEECAR			* Llamamos a leecar
                        MOVE.L 		#$ffffffff,D4
                        CMP.L		D4,D0			* Buffer interno vacio??
                        BEQ		RTB_VACIO			
                        MOVE.B		D0,TBB			* mete el caracter 
                        JMP     	FIN_RTI	
	RTB_VACIO:
                        CLR 		D1
                        CLR 		D3
                        MOVE.B 		IMRDUP,D1
                        MOVE.B		#%11101111,D3
                        AND.B 		D3,D1
                        MOVE.B		D1,IMRDUP
                        MOVE.B		IMRDUP,IMR
                        JMP     	FIN_RTI	

	RTI_RC_B:
                        CLR		D0			* Pongo D0 a 0 -> ESCCAR uso buffer recepcion A
                        CLR 		D1			* Pongo D1 a 0
                        MOVE.B		RBB,D1			* Guardo los datos del buffer de recepcion de A en D1
                        MOVE.L		#%00000001,D0
                        BSR		ESCCAR			* LLamadita a ESCCAR		
                        JMP		FIN_RTI			* D0 != -1 a comparar otra vez

*************************** FIN RTI ****************************************************
** Control de excepciones
Conf_Exc:   MOVE.L #BUS_ERR,$8          * Install BUS ERROR handler
            MOVE.L #ADDR_ERR,$c         * Install ADDRESS ERROR handler
            MOVE.L #ILLG_INS,$10        * Install ILLEGAL INSTRUCTION handler
            MOVE.L #PRI_VIOL,$20        * Install PRIVILEGE VIOLATION handler
            * No es necesario usarlo.
            *MOVE.L #TRACE,$24           * Para usar el modo traza y averiguar condiciones de carrera
            MOVE.L #ILLG_INS,$28        * Install EMULATION 1010 INSTRUCTION handler
            MOVE.L #ILLG_INS,$2c        * Install EMULATION 1111 INSTRUCTION handler
            RTS

CHAR:       DC.B 'ab'
TIMESTRC:   DC.L 0
** Trace: Interuption level: 5
TRACE:      MOVE.L D0,-(A7)
            MOVE.W SR,D0
            CMP.L #$2500,D0
            BGT RETURNT
            MOVEM.L D1/D2/D3/D4/D5/D6/D7/A0/A1/A2/A3/A4/A5/A6,-(A7)   ** Registros guardados
            MOVE.L #0,D0
            MOVE.B CHAR,D1
            ADDQ.B #1,CHAR
            BSR LEECAR
            MOVEM.L (A7)+,A6/A5/A4/A3/A2/A1/A0/D7/D6/D5/D4/D3/D2/D1   ** Registros restaurados
RETURNT:    MOVE.L (A7)+,D0
            RTE
            

** Handler minimo de BUS ERROR
BUS_ERR:    BSR StackBEr
            BREAK
            ADDA.L #8,A7                * Recuerda que los registros han sido modificados y que debes de revisar
            RTE                         *   la instruccion anterior y no la que apunta el PC.

Max_MEM     EQU     $8000
StackBEr:   MOVE.L #$bbbbeeee,D2        * Marca de que ha pcurrido un Address Error
            MOVE.W 4(A7),D3             * W/R:4b, I/N:3b, FUNC CODE:[2,0]bs
            MOVE.L 6(A7),D4             * Access Address
            MOVE.W 10(A7),D5            * Instruction Register:[15,0]bs
            MOVE.W 12(A7),D6            * Status Register(SR):[15,0]bs
            * Buscar quien causó el problema(solo posible para accesos usando un An)
            CMP.L #$8000,A0
            BLT BE_IN_A1
            MOVE.L A0,D4
            BRA BE_FIN
BE_IN_A1:   CMP.L #Max_MEM,A1
            BLT BE_IN_A2
            MOVE.L A1,D4
            BRA BE_FIN
BE_IN_A2:   CMP.L #Max_MEM,A2
            BLT BE_IN_A3
            MOVE.L A2,D4
            BRA BE_FIN
BE_IN_A3:   CMP.L #Max_MEM,A3
            BLT BE_IN_A4
            MOVE.L A3,D4
            BRA BE_FIN
BE_IN_A4:   CMP.L #Max_MEM,A4
            BLT BE_IN_A5
            MOVE.L A4,D4
            BRA BE_FIN
BE_IN_A5:   CMP.L #Max_MEM,A5
            BLT BE_IN_A6
            MOVE.L A5,D4
            BRA BE_FIN
BE_IN_A6:   CMP.L #Max_MEM,A6
            BLT BE_IN_A7
            MOVE.L A6,D4
            BRA BE_FIN
BE_IN_A7:   CMP.L #Max_MEM,A7           * "Imposible de que pase", ya que de ser así se interrupme a si mismo.
            BLT BE_IN_PC
            MOVE.L A7,D4
            BRA BE_FIN
BE_IN_PC:   CMP.L #Max_MEM,14(A7)
            BLT BE_404
            MOVE.L 14(A7),D4
            *BREAK
            BRA BE_FIN
BE_404:     MOVE.L #-1,D4               * Si no lo causó nadie(An) escribir un -1 en D4
BE_FIN:     MOVE.L 14(A7),D7            * Program Counter(PC)
            RTS

** Handler minimo de ADDRESS ERROR
ADDR_ERR:   BSR StackAEr
            BREAK
            ADDA.L #8,A7                * Recuerda que los registros han sido modificados y que debes de revisar
            RTE                         *   la instruccion anterior y no la que apunta el PC.

StackAEr:   MOVE.L #$aaaaeeee,D2        * Marca de que ha pcurrido un Address Error
            MOVE.W 4(A7),D3             * W/R:4b, I/N:3b, FUNC CODE:[2,0]bs
            MOVE.L 6(A7),D4             * Access Address
            MOVE.W 10(A7),D5            * Instruction Register:[15,0]bs
            MOVE.W 12(A7),D6            * Status Register(SR):[15,0]bs
            * Buscar quien causó el problema(solo posible para accesos usando un An)
            MOVE.L A0,D4
            BTST #0,D4
            BEQ AE_IN_A1
            BRA AE_FIN
AE_IN_A1:   MOVE.L A1,D4
            BTST #0,D4
            BEQ AE_IN_A2
            BRA AE_FIN
AE_IN_A2:   MOVE.L A2,D4
            BTST #0,D4
            BEQ AE_IN_A3
            BRA AE_FIN
AE_IN_A3:   MOVE.L A3,D4
            BTST #0,D4
            BEQ AE_IN_A4
            BRA AE_FIN
AE_IN_A4:   MOVE.L A4,D4
            BTST #0,D4
            BEQ AE_IN_A5
            BRA AE_FIN
AE_IN_A5:   MOVE.L A5,D4
            BTST #0,D4
            BEQ AE_IN_A6
            BRA AE_FIN
AE_IN_A6:   MOVE.L A6,D4
            BTST #0,D4
            BEQ AE_IN_A7
            BRA AE_FIN
AE_IN_A7:   MOVE.L A7,D4                * "Imposible de que pase", ya que de ser así se interrupme a si mismo.
            BTST #0,D4
            BEQ AE_IN_PC
            BRA AE_FIN
AE_IN_PC:   MOVE.L 14(A7),D4
            BTST #0,D4
            BEQ AE_404
            *BREAK
            BRA AE_FIN
AE_404:     MOVE.L #-1,D4               * Si no lo causó nadie(An) escribir un -1 en D4
AE_FIN:     MOVE.L 14(A7),D7            * Program Counter(PC)
            RTS

ILLG_INS:   BSR StackGEr
            BREAK                       * Recuerda que los registros han sido modificados y que debes de revisar
            RTE                         *   la instruccion anterior y no la que apunta el PC.

PRI_VIOL:   BSR StackGEr
            BREAK                       * Recuerda que los registros han sido modificados y que debes de revisar
            RTE                         *   la instruccion anterior y no la que apunta el PC.

StackGEr:   MOVE.W 4(A7),D6             * Status Register(SR):[15,0]bs
            MOVE.L 6(A7),D7             * Program Counter(PC)
            RTS

** MAIN **
MAIN:       BSR rand
            BSR rand
            BSR rand
            BSR rand
            BSR rand
            BSR rand
            BSR Conf_Exc                * Configurar los 'handlers' para las excepciones
            BSR Test_0                  * Test a LEECAR
            BSR Check
    T0:     BSR Test_1                  * Test a ESCCAR
            BSR Check
    *T1:     BSR Test_2                  * Test a LINEA
     *       BSR Check
    T2:     BSR Test_3                  * Test a SCAN
            BSR Check
    T3:     BSR Test_4                  * Test a PRINT
            BSR Check
    T4:     BSR Test_5                  * Prueba visual (SCAN, PRINT, RTI)
FinTests:   BREAK


** Datos para las subrutinas a testear
DataTstA:   DS.L 8 * 32B
DataTstB:   DS.L 8 * 32B
DataTstC:   DS.L 8 * 32B
** Datos para las subrutinas auxiliares para realizar los tests
DataTstD:   DS.L 8 * 32B
DataTstE:   DS.L 8 * 32B
DataTstF:   DS.L 8 * 32B
DataTstG:   DS.L 8 * 32B
DataTstH:   DS.L 8 * 32B
DataTstI:   DS.L 8 * 32B
DataTstJ:   DS.L 8 * 32B
DataTstK:   DS.L 8 * 32B
DataTstL:   DS.L 8 * 32B

BufferA:    DS.L 16 * 64B
BufferB:    DS.L 16 * 64B
BufferC:    DS.L 16 * 64B
BufferD:    DS.L 16 * 64B
BufferE:    DS.L 16 * 64B
BufferF:    DS.L 16 * 64B
BufferG:    DS.L 16 * 64B
BufferH:    DS.L 16 * 64B

BufResA:    DS.L 16 * 64B
BufResB:    DS.L 16 * 64B
BufResC:    DS.L 16 * 64B
BufResD:    DS.L 16 * 64B
BufResE:    DS.L 16 * 64B
BufResF:    DS.L 16 * 64B
BufResG:    DS.L 16 * 64B
BufResH:    DS.L 16 * 64B

DataResA:   DS.L 8 * 32B
DataResB:   DS.L 8 * 32B

GetWell0:   DS.L 1 * Reservar memoria para el resultado del test
** Configuracion de 'Test_0'
Conf_T0:    LEA DataTstA,A0
            LEA DataTstD,A1
            LEA DataTstE,A2
            LEA DataTstF,A3
            LEA DataResA,A4
        ** Test_0.0
            MOVE.L #$0000,(A0)+
            MOVE.L #$0000,(A1)+
            MOVE.L #$0014,(A2)+
            MOVE.L #$0004,(A3)+
            MOVE.L #$0004,(A4)+
        ** Test_0.1
            MOVE.L #$0001,(A0)+
            MOVE.L #$0030,(A1)+
            MOVE.L #$0032,(A2)+
            MOVE.L #$0016,(A3)+
            MOVE.L #$0046,(A4)+
        ** Test_0.2
            MOVE.L #$0002,(A0)+
            MOVE.L #$0046,(A1)+
            MOVE.L #$001e,(A2)+
            MOVE.L #$0014,(A3)+
            MOVE.L #$005a,(A4)+
        ** Test_0.3
            MOVE.L #$0003,(A0)+
            MOVE.L #$00c8,(A1)+
            MOVE.L #$0001,(A2)+
            MOVE.L #$0000,(A3)+
            MOVE.L #$00c8,(A4)+
        ** Test_0.4
            MOVE.L #$0001,(A0)+
            MOVE.L #$0021,(A1)+
            MOVE.L #$0021,(A2)+
            MOVE.L #$0031,(A3)+
            MOVE.L #$ffffffff,(A4)+
        ** Test_0.5
            MOVE.L #$0002,(A0)+
            MOVE.L #$0039,(A1)+
            MOVE.L #$0035,(A2)+
            MOVE.L #$0034,(A3)+
            MOVE.L #$006d,(A4)+
        ** Test_0.6
            MOVE.L #$0003,(A0)+
            MOVE.L #$0058,(A1)+
            MOVE.L #$0003,(A2)+
            MOVE.L #$0002,(A3)+
            MOVE.L #$005a,(A4)+
        ** Test_0.7
            MOVE.L #$0010,(A0)+
            MOVE.L #$0082,(A1)+
            MOVE.L #$00c8,(A2)+
            MOVE.L #$0000,(A3)+
            MOVE.L #$0082,(A4)+
            RTS

** Test_0: Pruebas a LEECAR
Test_0:     BSR Conf_T0             * Configurar el test que se va a realizar
            LINK A6,#-28            * Marco de pila para las direcciones de los vectores para datos y resultados
            LEA DataTstA,A0
            LEA DataTstD,A1
            LEA DataTstE,A2
            LEA DataTstF,A3
            LEA DataResA,A4
            MOVE.L #0,(A7)          * Inicializar 'iterador'
            MOVE.L #0,4(A7)         * Inicializar 'GetWell0'
            MOVE.L A0,8(A7)         * Guardar dirección de 'DataTstA'
            MOVE.L A1,12(A7)        * Guardar direccion de 'DataTstD'
            MOVE.L A2,16(A7)        * Guardar direccion de 'DataTstE'
            MOVE.L A3,20(A7)        * Guardar direccion de 'DataTstF'
            MOVE.L A4,24(A7)        * Guardar direccion de 'DataResA'
bcl_0:      BSR INIT                * Iniciar los bufferes internos
            MOVE.L (A0),D0          * Pasar parametro 'Buffer'
            MOVE.L (A1),D1          * Pasar parametro 'Caracter'
            MOVE.L (A2),D2          * Pasar parametro 'Tamaño'
            BSR Fil_Buf
            MOVE.L 8(A7),A0         * Cargar dirección de 'DataTstA'
            MOVE.L 20(A7),A1        * Cargar direccion de 'DataTstF'
            MOVE.L (A0),D0          * Pasar parametro 'Buffer'
            MOVE.L (A1),D1          * Pasar parametro 'Tamaño'
            BSR Del_Buf
            MOVE.L 8(A7),A0         * Cargar dirección de 'DataTstA'
            MOVE.L (A0),D0          * Pasar parametro 'Buffer'
bsr_0:      BSR LEECAR
            MOVE.L 24(A7),A0        * Cargar direccion de 'DataResA'
            MOVE.L (A0),D1
            MOVE.L A7,D7
            ADD.L #4,D7
            MOVE.L D7,-(A7)         * Pasar parametro 'DirGW'
            MOVE.L D1,-(A7)         * Pasar parametro 'ObtRes'
            MOVE.L D0,-(A7)         * Pasar parametro 'ExpRes'
            BSR Act_GW              * Actualizar 'GetWell'
actgw_0:    ADDA.L #12,A7
            ADD.L #4,8(A7)          * Actualizar 'DataTstA'
            ADD.L #4,12(A7)         * Actualizar 'DataTstD'
            ADD.L #4,16(A7)         * Actualizar 'DataTstE'
            ADD.L #4,20(A7)         * Actualizar 'DataTstF'
            ADD.L #4,24(A7)         * Actualizar 'DataResA'
            MOVE.L 8(A7),A0         * Cargar 'DataTstA'
            MOVE.L 12(A7),A1        * Cargar 'DataTstD'
            MOVE.L 16(A7),A2        * Cargar 'DataTstE'
            ADD.L #1,(A7)           * Actualizar 'iterador'
            CMP.L #8,(A7)           * Comprobar que ha hecho los 8 tests.
            BNE bcl_0
            UNLK A6
            RTS

** Configuracion de 'Test_1'
Conf_T1:    LEA DataTstA,A0
            LEA DataTstB,A1
            LEA DataTstD,A2
            LEA DataTstE,A3
            LEA DataTstF,A4
            LEA DataResA,A5
        ** Test_1.0
            MOVE.L #$0000,(A0)+
            MOVE.L #$0061,(A1)+
            MOVE.L #$0000,(A2)+
            MOVE.L #$0014,(A3)+
            MOVE.L #$000a,(A4)+
            MOVE.L #$0000,(A5)+
        ** Test_1.1
            MOVE.L #$0002,(A0)+
            MOVE.L #$0062,(A1)+
            MOVE.L #$007a,(A2)+
            MOVE.L #$07d0,(A3)+
            MOVE.L #$0000,(A4)+
            MOVE.L #$ffffffff,(A5)+
        ** Test_1.2
            MOVE.L #$0001,(A0)+
            MOVE.L #$0068,(A1)+
            MOVE.L #$0010,(A2)+
            MOVE.L #$0bb8,(A3)+
            MOVE.L #$06d6,(A4)+
            MOVE.L #$0000,(A5)+
        ** Test_1.3
            MOVE.L #$0010,(A0)+
            MOVE.L #$007a,(A1)+
            MOVE.L #$000a,(A2)+
            MOVE.L #$012c,(A3)+
            MOVE.L #$012c,(A4)+
            MOVE.L #$0000,(A5)+
        ** Test_1.4
            MOVE.L #$0003,(A0)+
            MOVE.L #$0041,(A1)+
            MOVE.L #$0036,(A2)+
            MOVE.L #$0bb8,(A3)+
            MOVE.L #$03e8,(A4)+
            MOVE.L #$ffffffff,(A5)+
        ** Test_1.5
            MOVE.L #$0001,(A0)+
            MOVE.L #$005a,(A1)+
            MOVE.L #$00aa,(A2)+
            MOVE.L #$07d0,(A3)+
            MOVE.L #$029a,(A4)+
            MOVE.L #$0000,(A5)+
        ** Test_1.6
            MOVE.L #$0017,(A0)+
            MOVE.L #$0033,(A1)+
            MOVE.L #$0000,(A2)+
            MOVE.L #$02bc,(A3)+
            MOVE.L #$012c,(A4)+
            MOVE.L #$0000,(A5)+
        ** Test_1.7
            MOVE.L #$000e,(A0)+
            MOVE.L #$0033,(A1)+
            MOVE.L #$0070,(A2)+
            MOVE.L #$07d0,(A3)+
            MOVE.L #$014d,(A4)+
            MOVE.L #$0000,(A5)+
            RTS

Test_1:     BSR Conf_T1
            LINK A6,#-36
            LEA DataTstA,A0
            LEA DataTstB,A1
            LEA DataTstD,A2
            LEA DataTstE,A3
            LEA DataTstF,A4
            LEA DataResA,A5
            MOVE.L #0,(A7)          * Inicializar 'iterador'
            MOVE.L #0,4(A7)         * Inicializar 'GetWell0'
            MOVE.L A0,8(A7)         * Guardar dirección de 'DataTstA'
            MOVE.L A1,12(A7)        * Guardar direccion de 'DataTstB'
            MOVE.L A2,16(A7)        * Guardar direccion de 'DataTstD'
            MOVE.L A3,20(A7)        * Guardar direccion de 'DataTstE'
            MOVE.L A4,24(A7)        * Guardar direccion de 'DataTstF'
            MOVE.L A5,28(A7)        * Guardar direccion de 'DataResA'
bcl_1:      BSR INIT                * No modifica registros
            MOVE.L (A0),D0          * Pasar parametro 'Buffer'
            MOVE.L (A2),D1          * Pasar parametro 'Caracter'
            MOVE.L (A3),D2          * Pasar parametro 'Tamaño'
            BSR Fil_Buf
            CMP.L #-1,D0
            BNE skip_1_0
            MOVE.L 8(A7),A0         * Cargar dirección de 'DataTstA'
            MOVE.L 24(A7),A1        * Cargar direccion de 'DataTstF'
            MOVE.L (A0),D0          * Pasar parametro 'Buffer'
            MOVE.L (A1),D1          * Pasar parametro 'Tamaño'
            BSR Del_Buf
            MOVE.L 8(A7),A0         * Cargar dirección de 'DataTstA'
            MOVE.L 16(A7),A1        * Cargar direccion de 'DataTstD'
            MOVE.L 20(A7),A2        * Cargar direccion de 'DataTstE'
            MOVE.L (A0),D0          * Pasar parametro 'Buffer'
            MOVE.L (A1),D1          * Pasar parametro 'Caracter'
            MOVE.L (A2),D2          * Pasar parametro 'Tamaño'
            SUB.L #2000,D2          * Restar 2000 porque se ha llenado
            BSR Fil_Buf
            BRA skip_1_1
skip_1_0:   MOVE.L 8(A7),A0         * Cargar dirección de 'DataTstA'
            MOVE.L 24(A7),A1        * Cargar direccion de 'DataTstF'
            MOVE.L (A0),D0          * Pasar parametro 'Buffer'
            MOVE.L (A1),D1          * Pasar parametro 'Tamaño'
            BSR Del_Buf
skip_1_1:   MOVE.L 8(A7),A0         * Cargar direccion de 'DataTstA'
            MOVE.L 12(A7),A1        * Cargar direccion de 'DataTstF'
            MOVE.L (A0),D0          * Pasar parametro 'Buffer'
            MOVE.L (A1),D1          * Pasar parametro 'Caracter'
bsr_1:      BSR ESCCAR
            MOVE.L 28(A7),A1        * Cargar direccion de 'DataResA'
            MOVE.L (A1),D1          * Cargar dato de 'DataResA'
            MOVE.L A7,D7
            ADD.L #4,D7
            MOVE.L D7,-(A7)         * Pasar parametro 'DirGW'
            MOVE.L D1,-(A7)         * Pasar parametro 'ObtRes'
            MOVE.L D0,-(A7)         * Pasar parametro 'ExpRes'
            BSR Act_GW              * Actualizar 'GetWell'
agtgw_1:    ADDA.L #12,A7
            ADD.L #4,8(A7)          * Actualizar 'DataTstA'
            ADD.L #4,12(A7)         * Actualizar 'DataTstB'
            ADD.L #4,16(A7)         * Actualizar 'DataTstD'
            ADD.L #4,20(A7)         * Actualizar 'DataTstE'
            ADD.L #4,24(A7)         * Actualizar 'DataTstF'
            ADD.L #4,28(A7)         * Actualizar 'DataResA'
            MOVE.L 8(A7),A0         * Cargar 'DataTstA'
            MOVE.L 16(A7),A2        * Cargar 'DataTstD'
            MOVE.L 20(A7),A3        * Cargar 'DataTstE'
            ADD.L #1,(A7)           * Actualizar 'iterador'
            CMP.L #8,(A7)
            BNE bcl_1
            UNLK A6
            RTS

Conf_T2:    LEA DataTstA,A0
            LEA DataTstD,A1
            LEA DataTstE,A2
            LEA DataTstF,A3
            LEA DataResA,A4
        ** Test_2.0
            MOVE.L #$0000,(A0)+
            MOVE.L #$0000,(A1)+
            MOVE.L #$0014,(A2)+
            MOVE.L #$0004,(A3)+
            MOVE.L #$000a,(A4)+
        ** Test_2.1
            MOVE.L #$0001,(A0)+
            MOVE.L #$0030,(A1)+
            MOVE.L #$0032,(A2)+
            MOVE.L #$0016,(A3)+
            MOVE.L #$0000,(A4)+
        ** Test_2.2
            MOVE.L #$0002,(A0)+
            MOVE.L #$0046,(A1)+
            MOVE.L #$001e,(A2)+
            MOVE.L #$0014,(A3)+
            MOVE.L #$0000,(A4)+
        ** Test_2.3
            MOVE.L #$0003,(A0)+
            MOVE.L #$00c8,(A1)+
            MOVE.L #$0001,(A2)+
            MOVE.L #$0000,(A3)+
            MOVE.L #$0000,(A4)+
        ** Test_2.4
            MOVE.L #$0001,(A0)+
            MOVE.L #$0021,(A1)+
            MOVE.L #$0021,(A2)+
            MOVE.L #$0031,(A3)+
            MOVE.L #$0000,(A4)+
        ** Test_2.5
            MOVE.L #$0002,(A0)+
            MOVE.L #$0039,(A1)+
            MOVE.L #$0035,(A2)+
            MOVE.L #$0034,(A3)+
            MOVE.L #$0000,(A4)+
        ** Test_2.6
            MOVE.L #$0003,(A0)+
            MOVE.L #$00ff,(A1)+
            MOVE.L #$000c,(A2)+
            MOVE.L #$0000,(A3)+
            MOVE.L #$0000,(A4)+
        ** Test_2.7
            MOVE.L #$0010,(A0)+
            MOVE.L #$0082,(A1)+
            MOVE.L #$00c8,(A2)+
            MOVE.L #$0000,(A3)+
            MOVE.L #$008c,(A4)+
            RTS

Test_2:     BSR Conf_T2             * Configurar el test que se va a realizar
            LINK A6,#-28            * Marco de pila para las direcciones de los vectores para datos y resultados
            LEA DataTstA,A0
            LEA DataTstD,A1
            LEA DataTstE,A2
            LEA DataTstF,A3
            LEA DataResA,A4
            MOVE.L #0,(A7)          * Inicializar 'iterador'
            MOVE.L #0,4(A7)         * Inicializar 'GetWell0'
            MOVE.L A0,8(A7)         * Guardar dirección de 'DataTstA'
            MOVE.L A1,12(A7)        * Guardar direccion de 'DataTstD'
            MOVE.L A2,16(A7)        * Guardar direccion de 'DataTstE'
            MOVE.L A3,20(A7)        * Guardar direccion de 'DataTstF'
            MOVE.L A4,24(A7)        * Guardar direccion de 'DataResA'
bcl_2:      BSR INIT                * Iniciar los bufferes internos
            MOVE.L (A0),D0          * Pasar parametro 'Buffer'
            MOVE.L (A1),D1          * Pasar parametro 'Caracter'
            MOVE.L (A2),D2          * Pasar parametro 'Tamaño'
            BSR Fil_Buf
            MOVE.L 8(A7),A0         * Cargar dirección de 'DataTstA'
            MOVE.L 20(A7),A1        * Cargar direccion de 'DataTstF'
            MOVE.L (A0),D0          * Pasar parametro 'Buffer'
            MOVE.L (A1),D1          * Pasar parametro 'Tamaño'
            BSR Del_Buf
            MOVE.L 8(A7),A0         * Cargar dirección de 'DataTstA'
            MOVE.L (A0),D0          * Pasar parametro 'Buffer'
actgw_2:    ADDA.L #12,A7
            ADD.L #4,8(A7)          * Actualizar 'DataTstA'
            ADD.L #4,12(A7)         * Actualizar 'DataTstD'
            ADD.L #4,16(A7)         * Actualizar 'DataTstE'
            ADD.L #4,20(A7)         * Actualizar 'DataTstF'
            ADD.L #4,24(A7)         * Actualizar 'DataResA'
            MOVE.L 8(A7),A0         * Cargar 'DataTstA'
            MOVE.L 12(A7),A1        * Cargar 'DataTstD'
            MOVE.L 16(A7),A2        * Cargar 'DataTstE'
            ADD.L #1,(A7)           * Actualizar 'iterador'
            CMP.L #8,(A7)           * Comprobar que ha hecho los 8 tests.
            BNE bcl_2
            UNLK A6
            RTS

Conf_T3:    LEA DataTstA,A0         * Buffer (SCAN)
        ** Buffer (SCAN)
            MOVE.L #BufferA,(A0)+
            MOVE.L #BufferB,(A0)+
            MOVE.L #BufferC,(A0)+
            MOVE.L #BufferD,(A0)+
            MOVE.L #BufferE,(A0)+
            MOVE.L #BufferF,(A0)+
            MOVE.L #BufferG,(A0)+
            MOVE.L #BufferH,(A0)+
            LEA DataTstB,A0         * Descriptor (SCAN)
        ** Descriptor (SCAN)
            MOVE.W #$ffff,(A0)+
            MOVE.W #$0002,(A0)+
            MOVE.W #$0000,(A0)+
            MOVE.W #$0001,(A0)+
            MOVE.W #$0001,(A0)+
            MOVE.W #$0000,(A0)+
            MOVE.W #$0001,(A0)+
            MOVE.W #$0001,(A0)+
            LEA DataTstC,A0         * Tamaño (SCAN)
        ** Tamaño (SCAN)
            MOVE.W #$000a,(A0)+
            MOVE.W #$000a,(A0)+
            MOVE.W #$0014,(A0)+
            MOVE.W #$001e,(A0)+
            MOVE.W #$000a,(A0)+
            MOVE.W #$003c,(A0)+
            MOVE.W #$0000,(A0)+
            MOVE.W #$0010,(A0)+
            LEA DataTstD,A0         * Caracter (Fil_BufC)
        ** Caracter (Fil_BufC)
            MOVE.L #$0041,(A0)+
            MOVE.L #$006e,(A0)+
            MOVE.L #$0016,(A0)+
            MOVE.L #$006d,(A0)+
            MOVE.L #$0069,(A0)+
            MOVE.L #$006d,(A0)+
            MOVE.L #$0069,(A0)+
            MOVE.L #$0073,(A0)+
            LEA DataTstE,A0         * Tamaño (Fil_BufC)
        ** Tamaño (Fil_BufC)
            MOVE.L #$0000,(A0)+
            MOVE.L #$0000,(A0)+
            MOVE.L #$0000,(A0)+
            MOVE.L #$0007,(A0)+
            MOVE.L #$0000,(A0)+
            MOVE.L #$0004,(A0)+
            MOVE.L #$000b,(A0)+
            MOVE.L #$0000,(A0)+
            LEA DataTstF,A0         * Ejecuciones (Hello_W)
        ** Ejecuciones (Hello_W)
            MOVE.L #$0005,(A0)+
            MOVE.L #$0003,(A0)+
            MOVE.L #$0001,(A0)+
            MOVE.L #$0002,(A0)+
            MOVE.L #$0001,(A0)+
            MOVE.L #$0005,(A0)+
            MOVE.L #$0002,(A0)+
            MOVE.L #$0001,(A0)+
            LEA DataResA,A0         * Resultados(D0) de SCAN
        ** Resultados(D0) de SCAN
            MOVE.L #$ffffffff,(A0)+
            MOVE.L #$ffffffff,(A0)+
            MOVE.L #$000c,(A0)+
            MOVE.L #$001e,(A0)+
            MOVE.L #$0000,(A0)+
            MOVE.L #$003c,(A0)+
            MOVE.L #$0000,(A0)+
            MOVE.L #$000c,(A0)+
            LEA DataResB,A0         * Resultados de SCAN (Salida en buffer)
        ** Resultados de SCAN (Salida en buffer)
            MOVE.L #BufResA,(A0)+
            MOVE.L #BufResB,(A0)+
            MOVE.L #BufResC,(A0)+
            MOVE.L #BufResD,(A0)+
            MOVE.L #BufResE,(A0)+
            MOVE.L #BufResF,(A0)+
            MOVE.L #BufResG,(A0)+
            MOVE.L #BufResH,(A0)+
        ** Configuracion de los BufferX
            MOVE.L #BufferA,D0      * Al ser bufferes consecutivos solo es necesario uno.
            MOVE.L #$0400,D1
            BSR Del_Mem
        ** Configuracion de los BufResX
            MOVE.L #BufResC,A0
            BSR Hello_Wm
            MOVE.L #BufResD,A0
            MOVE.L #$6d6d6d6d,(A0)+
            MOVE.W #$6d6d,(A0)+
            MOVE.B #$6d,(A0)+
            BSR Hello_Wm
            SUBA.L #1,A0
            BSR Hello_Wm
            MOVE.L #BufResF,A0
            MOVE.L #$6d6d6d6d,(A0)+
            BSR Hello_Wm
            SUBA.L #1,A0
            BSR Hello_Wm
            SUBA.L #1,A0
            BSR Hello_Wm
            SUBA.L #1,A0
            BSR Hello_Wm
            SUBA.L #1,A0
            BSR Hello_Wm
            MOVE.L #BufResH,A0
            BSR Hello_Wm
            RTS

** Test_3: Pruebas a SCAN
Test_3:     BSR Conf_T3             * Configurar el test que se va a realizar
            LINK A6,#-40            * Marco de pila para las direcciones de los vectores para datos y resultados
            LEA DataTstA,A0
            LEA DataTstB,A1
            LEA DataTstC,A2
            LEA DataTstD,A3
            LEA DataTstE,A4
            LEA DataTstF,A5
            MOVE.L #0,(A7)          * Inicializar 'iterador'
            MOVE.L #0,4(A7)         * Inicializar 'GetWell0'
            MOVE.L A0,8(A7)         * Guardar dirección de 'DataTstA'
            MOVE.L A1,12(A7)        * Guardar direccion de 'DataTstB'
            MOVE.L A2,16(A7)        * Guardar direccion de 'DataTstC'
            MOVE.L A3,20(A7)        * Guardar direccion de 'DataTstD'
            MOVE.L A4,24(A7)        * Guardar direccion de 'DataTstE'
            MOVE.L A5,28(A7)        * Guardar direccion de 'DataTstF'
            LEA DataResA,A0
            LEA DataResB,A2
            MOVE.L A0,32(A7)        * Guardar direccion de 'DataResA'
            MOVE.L A2,36(A7)        * Guardar direccion de 'DataResB'
bcl_3:      BSR INIT                * Iniciar los bufferes internos, no debe de tocar ningun registro.
            * Al haber una correspondencia directa se puede usar el mismo parametro que en SCAN
            MOVE.W (A1),D0          * Pasar parametro 'Buffer'
            MOVE.L (A3),D1          * Pasar parametro 'Caracter'
            MOVE.L (A4),D2          * Pasar parametro 'Tamaño'
            BSR Fil_BufC
            MOVE.L 28(A7),A0        * Cargar direccion de 'DataTstF'
            MOVE.L (A0),D6          * Cargar las veces que se ejecutara Hello_WnCR
bcl_3_1:    TST.L D6
            BEQ skip_3
            MOVE.L D6,-(A7)         * El viejo truco de meter una variable en pila para luego usarla mas tarde.
            MOVE.L 16(A7),A0        * Cargar direccion de 'DataTstB'
            MOVE.W (A0),D0          * Pasar parametro 'Buffer'
            BSR HeloWnCR
            MOVE.L (A7)+,D6         * Recuperamos el iterador con el 'viejo truco'
            SUB.L #1,D6
            BRA bcl_3_1
skip_3:     MOVE.L #$0d,D1          * Introducir el <CR>
            MOVE.L 12(A7),A0        * Cargar dirección de 'DataTstB'
            MOVE.W (A0),D0          * Pasar parametro 'Buffer'
            BSR ESCCAR
            MOVE.L 8(A7),A0         * Cargar dirección de 'DataTstA'
            MOVE.L 12(A7),A1        * Cargar direccion de 'DataTstB'
            MOVE.L 16(A7),A2        * Cargar direccion de 'DataTstC'
            MOVE.W (A2),-(A7)       * Pasar parametro 'Tamaño'
            MOVE.W (A1),-(A7)       * Pasar parametro 'Descriptor'
            MOVE.L (A0),-(A7)       * Pasar parametro 'Buffer'
bsr_3:      BSR SCAN
            ****************************************************************************************
            ADDA.L #8,A7            * Limpiar parametros de pila
            MOVE.L 32(A7),A0        * Cargar direccion de 'DataResA'
            MOVE.L (A0),D1          * Sacar el dato que se espera
            MOVE.L #$0f,D3
            CMP.L D0,D1             * Compara el resultado obtenido con el esperado de D0
            BNE cmp_3
            SUB.L #2,D3
cmp_3:      MOVE.L 8(A7),A0
            MOVE.L 36(A7),A1
            MOVE.L D3,-(A7)         * Guardar el resultado del test para ponerlo en 'GetWell'
            MOVE.L (A0),-(A7)
            MOVE.L (A1),-(A7)
            BSR strcmp
            ADDA.L #8,A7
            MOVE.L (A7)+,D3
            CMP.L #0,D0
            BNE cmp_3_1
            SUB.L #3,D3
cmp_3_1:    MOVE.L A7,D7
            ADD.L #4,D7
            MOVE.L D7,-(A7)         * Pasar parametro 'DirGW'
            MOVE.W D3,-(A7)         * Pasar parametro 'Data'
            BSR Put_GW
            ****************************************************************************************
actgw_3:    ADDA.L #6,A7
            ADD.L #4,8(A7)          * Actualizar 'DataTstA'
            ADD.L #2,12(A7)         * Actualizar 'DataTstB'
            ADD.L #2,16(A7)         * Actualizar 'DataTstC'
            ADD.L #4,20(A7)         * Actualizar 'DataTstD'
            ADD.L #4,24(A7)         * Actualizar 'DataTstE'
            ADD.L #4,28(A7)         * Actualizar 'DataTstF'
            ADD.L #4,32(A7)         * Actualizar 'DataResA'
            ADD.L #4,36(A7)         * Actualizar 'DataResB'
            MOVE.L 12(A7),A1         * Cargar 'DataTstA'
            MOVE.L 20(A7),A3        * Cargar 'DataTstD'
            MOVE.L 24(A7),A4        * Cargar 'DataTstE'
            ADD.L #1,(A7)           * Actualizar 'iterador'
            CMP.L #8,(A7)           * Comprobar que ha hecho los 8 tests.
            BNE bcl_3
            UNLK A6
            RTS

Test_4:     
            RTS

** Cosas para la prueba concurrente
** Una modificacion directa del tester del DATSI
BUFFER:     DS.B 2100       * Buffer para lectura y escritura de caracteres
CONTL:      DC.W 0          * Contador de lı́neas
CONTC:      DC.W 0          * Contador de caracteres
DIRLEC:     DC.L 0          * Dirección de lectura para SCAN
DIRESC:     DC.L 0          * Dirección de escritura para PRINT
TAME:       DC.W 0          * Tamano de escritura para print
DESA:       EQU  0          * Descriptor lı́nea A
DESB:       EQU  1          * Descriptor lı́nea B
NLIN:       EQU  5          * Número de lı́neas a leer
TAML:       EQU  30         * Tamano de lı́nea para SCAN
TAMB:       EQU  5          * Tamano de bloque para PRINT
InitWord:   DC.L 0          * Puntero al inicio de la palabra escrita
WordExit:   DC.B 'exit'

Test_5:     BSR Conf_Exc
            BSR INIT
            MOVE.W #$2000,SR

BUCPR:      MOVE.W #0,CONTC
            MOVE.W #NLIN,CONTL
            MOVE.L #BUFFER,DIRLEC
OTRAL:      MOVE.W #TAML,-(A7)
            MOVE.W #DESA,-(A7)
            MOVE.L DIRLEC,-(A7)
ESPL:       BSR SCAN
            TST.L D0
            BEQ ESPL
            ADD.L #8,A7

            MOVE.W D0,-(A7)
            MOVE.W #DESA,-(A7)
            MOVE.L DIRLEC,-(A7)

            MOVE.L (DIRLEC),InitWord
            ADD.L D0,DIRLEC
            ADD.W D0,CONTC

            BSR PRINT               * Eco por la linea donde se escribe (linea A)
            ADD.L #8,A7
            ** Comparar si ha escrito algo que comience por 'exit'
            MOVE.L (InitWord),A0
            MOVE.L #WordExit,A1
            MOVE.L #4,D0
Cmp_exit:   CMPM.B (A1)+,(A0)+
            BNE Skip_CMP
            SUB.L #1,D0
            TST.L D0
            BNE Cmp_exit
            BRA FIN
            
Skip_CMP:   SUB.W #1,CONTL
            BNE OTRAL

            MOVE.L #BUFFER,DIRLEC
OTRAE:      MOVE.W #TAMB,TAME
ESPE:       MOVE.W TAME,-(A7)
            MOVE.W #DESB,-(A7)
            MOVE.L DIRLEC,-(A7)
            BSR PRINT
            ADD.L #8,A7
            ADD.L D0,DIRLEC
            SUB.W D0,CONTC
            BEQ SALIR
            SUB.W D0,TAME
            BNE ESPE
            CMP.W #TAMB,CONTC
            BHI OTRAE
            MOVE.W CONTC,TAME
            BRA ESPE
SALIR:      BRA BUCPR
FIN:        BREAK * NOTE: Cambiar a RTS.


** Erase: Pondrá a 0 una parte de la memoria.
Erase:      MOVE.L #0,(A0)+
            SUB.L #4,D0
            TST.L D0
            BNE Erase
            RTS

** NICE: El resultado será modificar la memoria entre [0x7200, 0x7440) dejandola así:

** 007200: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
** 007218: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
** 007230: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
** 007248: 00 00 00 00 00 ff ff ff 00 00 00 00 00 00 00 00 ff ff ff 00 00 00 00 00 
** 007260: 00 00 00 00 ff 00 00 00 ff 00 00 00 00 00 00 ff 00 00 00 ff 00 00 00 00 
** 007278: 00 00 00 00 ff 00 00 00 ff 00 00 00 00 00 00 ff 00 00 00 ff 00 00 00 00 
** 007290: 00 00 00 00 ff 00 11 11 ff 00 00 00 00 00 00 ff 00 11 11 ff 00 00 00 00 
** 0072a8: 00 00 00 00 ff 00 11 11 ff 00 00 00 00 00 00 ff 00 11 11 ff 00 00 00 00 
** 0072c0: 00 00 00 00 00 ff ff ff 00 00 00 00 00 00 00 00 ff ff ff 00 00 00 00 00 
** 0072d8: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
** 0072f0: 00 00 00 ff 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff 00 00 00 
** 007308: 00 00 ff ff 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff ff 00 00 
** 007320: 00 ff ff ff ff 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff ff ff ff 00 
** 007338: 00 00 00 ff ff ff 00 00 00 00 00 00 00 00 00 00 00 00 ff ff ff 00 00 00 
** 007350: 00 00 00 00 00 ff ff ff 00 00 00 00 00 00 00 00 ff ff ff 00 00 00 00 00 
** 007368: 00 00 00 00 00 00 ff ff ff ff ff ff ff ff ff ff ff ff 00 00 00 00 00 00 
** 007380: 00 00 00 00 00 00 00 00 ff ff ff ff ff ff ff ff 00 00 00 00 00 00 00 00 
** 007398: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
** 0073b0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
** 0073c8: 00 00 00 ff 00 00 00 ff 00 ff ff ff 00 00 ff ff ff 00 ff ff ff 00 00 00 
** 0073e0: 00 00 00 ff ff 00 00 ff 00 00 ff 00 00 ff 00 00 00 00 ff 00 00 00 00 00 
** 0073f8: 00 00 00 ff 00 ff 00 ff 00 00 ff 00 00 ff 00 00 00 00 ff ff 00 00 00 00 
** 007410: 00 00 00 ff 00 00 ff ff 00 00 ff 00 00 ff 00 00 00 00 ff 00 00 00 00 00 
** 007428: 00 00 00 ff 00 00 00 ff 00 ff ff ff 00 00 ff ff ff 00 ff ff ff 00 00 00 

NICE:       LINK A6,#-8
            MOVE.L #$0240,(A7)
            MOVE.L #$7200,4(A7)
            MOVE.L (A7),D0
            MOVE.L 4(A7),A0
            BSR Erase
            MOVE.L 4(A7),A0
            ** Ojos
            ADDA.L #76,A0
            MOVE.L #$00ffffff,(A0)+ * Linea 4
            ADDA.L #8,A0
            MOVE.L #$ffffff00,(A0)+
            ADDA.L #8,A0
            MOVE.L #$ff000000,(A0)+ * Linea 5
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$000000ff,(A0)+
            ADDA.L #8,A0
            MOVE.L #$ff000000,(A0)+ * Linea 6
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$000000ff,(A0)+
            ADDA.L #8,A0
            MOVE.L #$ff00ffff,(A0)+ * Linea 7
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$00ffffff,(A0)+
            ADDA.L #8,A0
            MOVE.L #$ff00ffff,(A0)+ * Linea 8
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$00ffffff,(A0)+
            ADDA.L #8,A0
            MOVE.L #$00ffffff,(A0)+ * Linea 9
            ADDA.L #8,A0
            MOVE.L #$ffffff00,(A0)+
            ADDA.L #28,A0
            ** Boca
            MOVE.L #$000000ff,(A0)+ * Linea 11
            ADDA.L #16,A0
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$0000ffff,(A0)+ * Linea 12
            ADDA.L #16,A0
            MOVE.L #$ffff0000,(A0)+
            MOVE.L #$00ffffff,(A0)+ * Linea 13
            MOVE.L #$ff000000,(A0)+
            ADDA.L #8,A0
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$ffffff00,(A0)+
            MOVE.L #$000000ff,(A0)+ * Linea 14
            MOVE.L #$ffff0000,(A0)+
            ADDA.L #8,A0
            MOVE.L #$0000ffff,(A0)+
            MOVE.L #$ff000000,(A0)+
            ADDA.L #4,A0
            MOVE.L #$00ffffff,(A0)+ * Linea 15
            ADDA.L #8,A0
            MOVE.L #$ffffff00,(A0)+
            ADDA.L #8,A0
            MOVE.L #$0000ffff,(A0)+ * Linea 16
            MOVE.L #$ffffffff,(A0)+
            MOVE.L #$ffffffff,(A0)+
            MOVE.L #$ffff0000,(A0)+
            ADDA.L #12,A0
            MOVE.L #$ffffffff,(A0)+ * Linea 17
            MOVE.L #$ffffffff,(A0)+
            ADDA.L #56,A0
            ** Texto
            MOVE.L #$000000ff,(A0)+ * Linea 20
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$00ffffff,(A0)+
            MOVE.L #$0000ffff,(A0)+
            MOVE.L #$ff00ffff,(A0)+
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$000000ff,(A0)+ * Linea 21
            MOVE.L #$ff0000ff,(A0)+
            MOVE.L #$0000ff00,(A0)+
            MOVE.L #$00ff0000,(A0)+
            MOVE.L #$0000ff00,(A0)+
            ADDA.L #4,A0
            MOVE.L #$000000ff,(A0)+ * Linea 22
            MOVE.L #$00ff00ff,(A0)+
            MOVE.L #$0000ff00,(A0)+
            MOVE.L #$00ff0000,(A0)+
            MOVE.L #$0000ffff,(A0)+
            ADDA.L #4,A0
            MOVE.L #$000000ff,(A0)+ * Linea 23
            MOVE.L #$0000ffff,(A0)+
            MOVE.L #$0000ff00,(A0)+
            MOVE.L #$00ff0000,(A0)+
            MOVE.L #$0000ff00,(A0)+
            ADDA.L #4,A0
            MOVE.L #$000000ff,(A0)+ * Linea 24
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$00ffffff,(A0)+
            MOVE.L #$0000ffff,(A0)+
            MOVE.L #$ff00ffff,(A0)+
            MOVE.L #$ff000000,(A0)+
            UNLK A6
            RTS
            
** CRUDE: El resultado será modificar la memoria entre [0x7200, 0x7440) dejandola así:

** 007200: 00 00 00 00 00 ff ff ff 00 00 00 00 00 00 00 00 ff ff ff 00 00 00 00 00 
** 007218: 00 00 00 00 00 00 ff ff ff 00 00 00 00 00 00 ff ff ff 00 00 00 00 00 00 
** 007230: 00 00 00 00 00 00 00 00 ff ff 00 00 00 00 ff ff 00 00 00 00 00 00 00 00 
** 007248: 00 00 00 00 00 ff ff ff 00 00 00 00 00 00 00 00 ff ff ff 00 00 00 00 00 
** 007260: 00 00 00 00 ff 00 00 00 ff 00 00 00 00 00 00 ff 00 00 00 ff 00 00 00 00 
** 007278: 00 00 00 00 ff 00 ff 00 ff 00 00 00 00 00 00 ff 00 ff 00 ff 00 00 00 00 
** 007290: 00 00 00 00 ff ff ff ff ff 00 00 00 00 00 00 ff ff ff ff ff 00 00 00 00 
** 0072a8: 00 00 00 00 ff ff ff ff ff 00 00 00 00 00 00 ff ff ff ff ff 00 00 00 00 
** 0072c0: 00 00 00 00 00 ff ff ff 00 00 00 00 00 00 00 00 ff ff ff 00 00 00 00 00 
** 0072d8: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
** 007380: 00 00 00 00 00 00 00 00 ff ff ff ff ff ff ff ff 00 00 00 00 00 00 00 00 
** 007368: 00 00 00 00 00 00 ff ff ff ff ff ff ff ff ff ff ff ff 00 00 00 00 00 00 
** 007350: 00 00 00 00 00 ff ff ff 00 00 00 00 00 00 00 00 ff ff ff 00 00 00 00 00 
** 007338: 00 00 00 ff ff ff 00 00 00 00 00 00 00 00 00 00 00 00 ff ff ff 00 00 00 
** 007320: 00 ff ff ff ff 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff ff ff ff 00 
** 007308: 00 00 ff ff 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff ff 00 00 
** 0072f0: 00 00 00 ff 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff 00 00 00 
** 007398: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
** 0073b0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
** 0073c8: 00 00 ff ff ff 00 ff ff ff 00 00 ff 00 00 ff 00 ff ff 00 00 ff ff ff 00 
** 0073e0: 00 ff 00 00 00 00 ff 00 00 ff 00 ff 00 00 ff 00 ff 00 ff 00 ff 00 00 00 
** 0073f8: 00 ff 00 00 00 00 ff ff ff 00 00 ff 00 00 ff 00 ff 00 ff 00 ff ff 00 00 
** 007410: 00 ff 00 00 00 00 ff 00 00 ff 00 ff 00 00 ff 00 ff 00 ff 00 ff 00 00 00 
** 007428: 00 00 ff ff ff 00 ff 00 00 ff 00 00 ff ff 00 00 ff ff 00 00 ff ff ff 00 

CRUDE:      LINK A6,#-8
            MOVE.L #$0240,(A7)
            MOVE.L #$7200,4(A7)
            MOVE.L (A7),D0
            MOVE.L 4(A7),A0
            BSR Erase
            MOVE.L 4(A7),A0
            ** Cejas
            ADDA.L #4,A0
            MOVE.L #$00ffffff,(A0)+ * Linea 1
            ADDA.L #8,A0
            MOVE.L #$ffffff00,(A0)+
            ADDA.L #8,A0
            MOVE.L #$0000ffff,(A0)+ * Linea 2
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$ffff0000,(A0)+
            ADDA.L #12,A0
            MOVE.L #$ffff0000,(A0)+ * Linea 3
            MOVE.L #$0000ffff,(A0)+
            ADDA.L #12,A0
            ** Ojos
            MOVE.L #$00ffffff,(A0)+ * Linea 4
            ADDA.L #8,A0
            MOVE.L #$ffffff00,(A0)+
            ADDA.L #8,A0
            MOVE.L #$ff000000,(A0)+ * Linea 5
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$000000ff,(A0)+
            ADDA.L #8,A0
            MOVE.L #$ff00ff00,(A0)+ * Linea 6
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$00ff00ff,(A0)+
            ADDA.L #8,A0
            MOVE.L #$ffffffff,(A0)+ * Linea 7
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$ffffffff,(A0)+
            ADDA.L #8,A0
            MOVE.L #$ffffffff,(A0)+ * Linea 8
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$ffffffff,(A0)+
            ADDA.L #8,A0
            MOVE.L #$00ffffff,(A0)+ * Linea 9
            ADDA.L #8,A0
            MOVE.L #$ffffff00,(A0)+
            ADDA.L #28,A0
            ** Boca
            ADDA.L #8,A0
            MOVE.L #$ffffffff,(A0)+ * Linea 11
            MOVE.L #$ffffffff,(A0)+
            ADDA.L #12,A0
            MOVE.L #$0000ffff,(A0)+ * Linea 12
            MOVE.L #$ffffffff,(A0)+
            MOVE.L #$ffffffff,(A0)+
            MOVE.L #$ffff0000,(A0)+
            ADDA.L #8,A0
            MOVE.L #$00ffffff,(A0)+ * Linea 13
            ADDA.L #8,A0
            MOVE.L #$ffffff00,(A0)+
            ADDA.L #4,A0
            MOVE.L #$000000ff,(A0)+ * Linea 14
            MOVE.L #$ffff0000,(A0)+
            ADDA.L #8,A0
            MOVE.L #$0000ffff,(A0)+
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$00ffffff,(A0)+ * Linea 15
            MOVE.L #$ff000000,(A0)+
            ADDA.L #8,A0
            MOVE.L #$000000ff,(A0)+
            MOVE.L #$ffffff00,(A0)+
            MOVE.L #$0000ffff,(A0)+ * Linea 16
            ADDA.L #16,A0
            MOVE.L #$ffff0000,(A0)+
            MOVE.L #$000000ff,(A0)+ * Linea 17
            ADDA.L #16,A0
            MOVE.L #$ff000000,(A0)+
            ADDA.L #48,A0
            ** Texto
            MOVE.L #$0000ffff,(A0)+ * Linea 20
            MOVE.L #$ff00ffff,(A0)+
            MOVE.L #$ff0000ff,(A0)+
            MOVE.L #$0000ff00,(A0)+
            MOVE.L #$ffff0000,(A0)+
            MOVE.L #$ffffff00,(A0)+
            MOVE.L #$00ff0000,(A0)+ * Linea 21
            MOVE.L #$0000ff00,(A0)+
            MOVE.L #$00ff00ff,(A0)+
            MOVE.L #$0000ff00,(A0)+
            MOVE.L #$ff00ff00,(A0)+
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$00ff0000,(A0)+ * Linea 22
            MOVE.L #$0000ffff,(A0)+
            MOVE.L #$ff0000ff,(A0)+
            MOVE.L #$0000ff00,(A0)+
            MOVE.L #$ff00ff00,(A0)+
            MOVE.L #$ffff0000,(A0)+
            MOVE.L #$00ff0000,(A0)+ * Linea 23
            MOVE.L #$0000ff00,(A0)+
            MOVE.L #$00ff00ff,(A0)+
            MOVE.L #$0000ff00,(A0)+
            MOVE.L #$ff00ff00,(A0)+
            MOVE.L #$ff000000,(A0)+
            MOVE.L #$0000ffff,(A0)+ * Linea 24
            MOVE.L #$ff00ff00,(A0)+
            MOVE.L #$00ff0000,(A0)+
            MOVE.L #$ffff0000,(A0)+
            MOVE.L #$ffff0000,(A0)+
            MOVE.L #$ffffff00,(A0)+
            UNLK A6
            RTS

** Subrutinas auxiliares

** Escribir 'Hola mundo!<CR>' en un buffer interno especificado mediante D0
** <IN> D0: buffer(1)
Hello_W:    LINK A6,#-2
            MOVE.W D0,(A7)
            MOVE.L #$48,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$6f,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$6c,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$61,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$20,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$6d,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$75,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$6e,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$64,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$6f,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$21,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$0d,D1
            BSR ESCCAR
            UNLK A6
            RTS

** Escribir 'Hola mundo!<CR>' en un buffer interno especificado mediante D0
** <IN> D0: buffer(1)
HeloWnCR:   LINK A6,#-2
            MOVE.W D0,(A7)
            MOVE.L #$48,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$6f,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$6c,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$61,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$20,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$6d,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$75,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$6e,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$64,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$6f,D1
            BSR ESCCAR
            MOVE.W (A7),D0
            MOVE.L #$21,D1
            BSR ESCCAR
            UNLK A6
            RTS

** Rellenar parte de un buffer con un caracter
** <IN> D0: buffer(1), D1: caracter(1), D2: tamaño(2)
Fil_BufC:   LINK A6,#-4
            MOVE.B D0,(A7)
            MOVE.B D1,1(A7)
            MOVE.W D2,2(A7)
bcl_FBC:    TST.W 2(A7)
            BEQ fin_FBC
            BSR ESCCAR
            CMP.L #-1,D0                * Para cuando este lleno
            BEQ fin_FB
            SUBQ.W #1,2(A7)
            MOVE.B (A7),D0
            MOVE.B 1(A7),D1
            MOVE.W 2(A7),D2
            BRA bcl_FBC
fin_FBC:    UNLK A6
            RTS

** Rellenar parte de un buffer con un caracter y sus consecutivos.
** <IN> D0: buffer(1), D1: caracter(1), D2: tamaño(2)
Fil_Buf:    LINK A6,#-4
            MOVE.B D0,(A7)
            MOVE.B D1,1(A7)
            MOVE.W D2,2(A7)
bcl_FB:     TST.W 2(A7)
            BEQ fin_FB
            BSR ESCCAR
            CMP.L #-1,D0                * Para cuando este lleno
            BEQ fin_FB
            ADDQ.B #1,1(A7)
            SUBQ.W #1,2(A7)
            MOVE.B (A7),D0
            MOVE.B 1(A7),D1
            MOVE.W 2(A7),D2
            BRA bcl_FB
fin_FB:     UNLK A6
            RTS

** Eliminar parte de un buffer
** <IN> D0: buffer(1), D1: tamaño(2)
Del_Buf:    LINK A6,#-4
            MOVE.B D0,1(A7)
            MOVE.W D1,2(A7)
bcl_DB:     TST.W 2(A7)
            BEQ fin_DB
            BSR LEECAR
            CMP.L #-1,D0                * Para cuando este vacio
            BEQ fin_DB
            SUBQ.W #1,2(A7)
            MOVE.B 1(A7),D0
            MOVE.W 2(A7),D1
            BRA bcl_DB
fin_DB:     UNLK A6
            RTS

** TODO: Modificar a que use parametros mediante pila.
** Rellenar parte de la memoria con un caracter
** <IN> D0: direccion(1), D1: caracter(1), D2: tamaño(2)
Fil_MemC:   MOVE.L D0,A0
bcl_FMC:    TST.W D2
            BEQ fin_FMC
            MOVE.B D1,(A0)+             * Escribir caracter
            SUBQ.W #1,D2
            TST.W D2
            BRA bcl_FMC
fin_FMC:    RTS

** Rellenar parte de la memoria con un caracter y escribiendo al final un <CR>
** <IN> D0: direccion(1), D1: caracter(1), D2: tamaño(2)
Fil_Mem:    MOVE.L D0,A0
bcl_FM:     TST.W D2
            BEQ fin_FM
            MOVE.B D1,(A0)+             * Escribir caracter
            SUBQ.W #1,D2
            TST.W D2
            BNE jmp_FM
            MOVE.B #$0d,(A0)+
jmp_FM:     BRA bcl_FM
fin_FM:     RTS

** 'Eliminar' parte de la memoria poniendo ceros.
** <IN> D0: direccion(1), D1: tamaño(2){en Bytes}
Del_Mem:    MOVE.L D0,A0
            *EOR.L D2,D2
bcl_DM:     TST.W D1
            BEQ fin_DM
            MOVE.B #0,(A0)+             * Escribir caracter
            SUBQ.W #1,D1
            BRA bcl_DM
fin_DM:     RTS

** Escribe en memoria, pasado mediante A0 "Hola mundo!<CR>"
Hello_Wm:   MOVE.B #$48,(A0)+
            MOVE.B #$6f,(A0)+
            MOVE.B #$6c,(A0)+
            MOVE.B #$61,(A0)+
            MOVE.B #$20,(A0)+
            MOVE.B #$6d,(A0)+
            MOVE.B #$75,(A0)+
            MOVE.B #$6e,(A0)+
            MOVE.B #$64,(A0)+
            MOVE.B #$6f,(A0)+
            MOVE.B #$21,(A0)+
            MOVE.B #$0d,(A0)+
            RTS

** strcmp (str1, str2): Compara los dos strings pasados por pila, que terminan en '\0',
**                      devuelve 0, si son iguales, 1 si str1>str2 o -1 si str1<str2
strcmp:     MOVE.L 4(A7),A0
            MOVE.L 8(A7),A1
scmp:       TST.B (A0)
            BNE scmpskip
            TST.B (A1)
            BNE scmpskip
            MOVE.L #0,D0
            BRA finscmp
scmpskip:   CMPM.B (A0)+,(A1)+
            BGT sup
            BLT sdown
            BRA scmp
sup:        MOVE.L #1,D0
            BRA finscmp
sdown:      MOVE.L #-1,D0
            BRA finscmp
finscmp:    RTS

** strncmp (n, str1, str2): Compara los dos strings como indique 'n', devuelve 0 si son iguales
**                          o un numero positivo que indica 'cuanto' se parecen
srtncmp:    MOVE.L 4(A7),D0
            MOVE.L 8(A7),A0
            MOVE.L 12(A7),A0
sncp:       TST.L D0
            BEQ finscnp
            SUB.L #1,D0
            CMPM.L (A0)+,(A1)+
            BEQ sncp
finscnp:    RTS

** Put_GW (Data, DirGw): Introduce el dato en 'GetWell', el dato se pasa como 2B pero solo es de 1B.
Put_GW:     MOVE.W 4(A7),D3
            MOVE.L 6(A7),A0
            MOVE.L (A0),D7
            ROL.L #4,D7
            ADD.B D3,D7
            MOVE.L D7,(A0)
            RTS

** Act_GW (ExpRes, ObtRes, DirGW): Comparara el valor de 'ExpRes' y 'ObtRes' y de ser iguales escribirá en 
**                                 'DirGW' un 0xA en caso contrario escribirá un 0xF.
Act_GW:     MOVE.L 4(A7),D0
            MOVE.L 8(A7),D1
            MOVE.L 12(A7),A0
            MOVE.L (A0),D7
            CMP.L D0,D1
            BEQ Act_GW_A
            ROL.L #4,D7
            ADD.B #$f,D7
            BRA Act_fin
Act_GW_A:   ROL.L #4,D7
            ADD.B #$a,D7
Act_fin:    MOVE.L D7,(A0)
            RTS

** Check (D7): Recibira el GetWellX por 'D7' y comprobará si ha habido algun fallo, tanto si todas las pruebas
**             se han pasado o no, entre las direcciones [0x7200,0x7400) se prondrá una imagen.
Check:      CMP.L #$aaaaaaaa,D7
            BNE Chk_Fail
            BSR NICE
            BRA Chk_Fin
Chk_Fail:   BSR CRUDE
            BREAK                   * Breakpoint, solo para CRUDE
Chk_Fin:    RTS

** rand (): Genera un numero pseudo-aleatorio en base a la especificacion de POSIX para C.
**          Xn+1 = (a*Xn + c)(mod m)
**          a = 0x41c64e6d, m = 0x8000, c = 0x3039, X0 = srand = 0x4e6658
srand:      DC.L 5318008
rand:       MOVE.L #$41c64e6d,D0    * a
            MOVE.L srand,D1         * Xn
            BSR MULUL
            ADD.L #$3039,D0         * c
            *MOVE.L #$8000,D1        * m
            *BSR mod                * No hacer 'mod' ya que despues se llamara a dicha funcion.
            MOVE.L D0,srand         * Xn+1
            RTS

** MULUL (m, n): Recibira dos numeros de 32bits para multiplicarlos.
** m = D0, n = D1, out = D0,D1
** m = a*0x10000 + b, n = c*0x10000 + d; m * n = a*c*0x100000000 + c*b*0x10000 + a*d*0x10000 + b*d
**                                               ^ no cuenta ^, se pasa del tamaño del registro
MULUL:      TST.W D0
            BNE nxtMULUL
            TST.W D1
            BNE nxtMULUL
            MOVE.L #0,D0
            BRA FinMULUL
nxtMULUL:   MOVE.L #16,D5
            CLR.L D6
            CLR.L D7
            MOVE.W D0,D4
            MULU D1,D4              * b*d -> D4
            MOVE.L D0,D3
            LSR.L D5,D3
            MOVE.L D3,D7
            MULU D1,D3              * a*d
            MOVE.L D3,D6
            LSR.L D5,D6             * a*d/0x10000
            MOVE.L D1,D2
            LSR.L D5,D2
            MULU D2,D7              * D7 -> a*c
            ADD.L D6,D7
            LSL.L D5,D3             * a*d*0x10000
            MULU D2,D0              * c*b
            MOVE.L D0,D6
            LSR.L D5,D6             * c*b/0x10000
            ADD.L D6,D7
            MOVE.L D7,D1            * a*c + (c*b + a*d)/0x10000
            LSL.L D5,D0             * c*b*0x10000
            ADD.L D3,D0
            ADD.L D4,D0
            BCC FinMULUL            * Si no hay acarreo, no sumarlo
            ADD.L #1,D1
FinMULUL:   RTS

** DIVUL (m, n): Recibira dos numberos de 32bits para divirlos. m/n
** m = D0, n = D1, out = D0,D2
** D0: resultado de la operacion, D2: resto de la division
DIVUL:      LINK A6,#-4
            TST.L D1
            BNE nxtcomp
            MOVE.L #-1,D0
            BRA FinDIVUL
nxtcomp:    MOVE.L D1,D3
            AND.L #$ffff0000,D3
            TST.L D3
            BNE nxtDIVUL
            DIVU D1,D0              * Como el divisor es del tamaño de palabra podemos usar la instruccion.
            AND.L #$0000ffff,D3
            BRA FinDIVUL
nxtDIVUL:   MOVE.L D0,D2
            CLR.L D0
            MOVE.L D1,(A7)
bclDIVUL:   TST.L D2                * m
            BEQ FinDIVUL
            BTST #31,D1             * bit a 1?
            BNE skpDVUL0
            BTST #31,D2             
            BNE skpDVUL2            * Provocamos que el programa siga porque D2 < D1
            BRA skpDVUL1
skpDVUL0:   BTST #31,D2             * 
            BEQ FinDIVUL            * Provocamos fin porque D2 > D1
skpDVUL1:   CMP.L D1,D2             * m < n?
            BLT FinDIVUL
skpDVUL2:   SUB.L D1,D2
            ADD.L #1,D0
            MOVE.L (A7),D1
            BRA bclDIVUL
FinDIVUL:   UNLK A6
            RTS

** mod (m, n): Recibirá dos numeros y hara dicha operacion m (mod n)
** m = D0, n = D1, out = D0
mod:        LINK A6,#-16            * Guardar 'm', 'n' y un 'res'
            MOVE.L D0,(A7)
            MOVE.L D1,4(A7)
            BSR DIVUL
            MOVE.L 4(A7),D1
            BSR MULUL               * No sería necesario hacer esto, DIVUL ya devuelve lo que devuelve 'mod'
            MOVE.L D0,D1
            MOVE.L (A7),D0
            SUB.L D1,D0             * m - (m/n) * n
            UNLK A6
            RTS


** Final de subrutinas auxiliares


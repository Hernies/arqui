************************************************************************
*************************** PROYECTO DE E/S ****************************
************************************************************************

		
        *ORG     $0
        *DC.L    $8000          * Pila
        *DC.L    PPAL           * PC
		

************************************************************************
************************ ETIQUETAS DE REGISTROS ************************
************************************************************************
* Aqui asignamos direccion a los registros de la DUART, de la forma:
* <Registro (Etiqueta)>  EQU  <Direccion>
************************************************************************

        ORG     $400

MR1A    EQU     $effc01       * de modo A (escritura)
MR2A    EQU     $effc01       * de modo A (2º escritura)
SRA     EQU     $effc03       * de estado A (lectura)
CSRA    EQU     $effc03       * de seleccion de reloj A (escritura)
CRA     EQU     $effc05       * de control A (escritura)
TBA     EQU     $effc07       * buffer transmision A (escritura)
RBA     EQU     $effc07       * buffer recepcion A  (lectura)

MR1B    EQU     $effc11       * de modo B (escritura)
MR2B    EQU     $effc11       * de modo B (2º escritura)
SRB     EQU     $effc13       * de estado B (lectura)
CSRB    EQU     $effc13       * de seleccion de reloj B (escritura)
CRB     EQU     $effc15       * de control B (escritura)
TBB     EQU     $effc17       * buffer transmision B (escritura)
RBB     EQU     $effc17       * buffer recepcion B  (lectura)

ACR		EQU		$effc09	      * de control auxiliar (escritura)
IMR     EQU     $effc0B       * de mascara de interrupcion A y B (escritura)
ISR     EQU     $effc0B       * de estado de interrupcion A y B (lectura)

IVR     EQU    	$effc19	      * vector de interrupcion (lectura y escritura, ambas lineas)

************************************************************************
********************** DEFINICION DE VARIABLES *************************
************************************************************************

* DC: Define constant <ETIQUETA> DC.<TAMAÑO> <ITEM>,<ITEM>,.. 
* A partir de la dir de memoria ETIQUETA se almacena <ITEM>, cada uno con TAMAÑO

* DS: Define storage <ETIQUETA> DS.<TAMAÑO> <LONGITUD>
* Genera bloque de bytes, palabras o palabras largas sin inicializar

*************************************************************************

A_BUF_SCAN:    DS.B  2001    * reservamos 2001B de buffer SCAN A
A_INI_SCAN:    DC.L  0       * inicio del buffer SCAN A
A_ESC_SCAN:    DC.L  0       * escribe el buffer (RTI)
A_LEC_SCAN:    DC.L  0       * lee del buffer
A_FIN_SCAN:    DC.L  0       * final del buffer

B_BUF_SCAN:    DS.B  2001    * reservamos 2001B de buffer SCAN B
B_INI_SCAN:    DC.L  0       * inicio del buffer SCAN B
B_ESC_SCAN:    DC.L  0       * escribe el buffer (RTI)
B_LEC_SCAN:    DC.L  0       * lee del buffer
B_FIN_SCAN:    DC.L  0       * final del buffer

A_BUF_PRINT:    DS.B  2001    * reservamos 2001B de buffer PRINT A
A_INI_PRINT:    DC.L  0       * inicio del buffer PRINT A
A_ESC_PRINT:    DC.L  0       * escribe el buffer 
A_LEC_PRINT:    DC.L  0       * lee del buffer (RTI)
A_FIN_PRINT:    DC.L  0       * final del buffer

B_BUF_PRINT:    DS.B  2001    * reservamos 2001B de buffer PRINT B
B_INI_PRINT:    DC.L  0       * inicio del buffer PRINT B
B_ESC_PRINT:    DC.L  0       * escribe el buffer 
B_LEC_PRINT:    DC.L  0       * lee del buffer (RTI)
B_FIN_PRINT:    DC.L  0       * final del buffer

COPIA_IMR       DC.B 0        * copia de IMR (Registro de mascara de interrupcion) Para poder leerlo
N_CHAR_A        DC.L 0        * numero de caracteres leidos en A
N_CHAR_B        DC.L 0        * numero de caracteres leidos en B

************************************************************************
******************************** INIT **********************************
************************************************************************

INIT	MOVE.B          #%00010000,CRA      * Reinicia el puntero de control CRA para acceder a MR1A
		MOVE.B          #%00010000,CRB      * Reinicia el puntero de control CRB para acceder a MR1B
        MOVE.B          #%00000011,MR1A     * 8 bits por caracter en A. Solicita una interrupcion cada caracter
        MOVE.B          #%00000011,MR1B     * 8 bits por caracter en B. Solicita una interrupcion cada caracter
        MOVE.B          #%00000000,MR2A     * Eco desactivado en A (No retransmite automaticamente cada caracter que recibe)
		MOVE.B          #%00000000,MR2B     * Eco desactivado en B (No retransmite automaticamente cada caracter que recibe)
        MOVE.B          #%00000000,ACR      * Seleccionamos velocidad conjunto 1 = 38400 bps
        MOVE.B          #%11001100,CSRA     * Velocidad = 38400 bps (tranmision y recepcion)
        MOVE.B          #%11001100,CSRB     * Velocidad = 38400 bps (tranmision y recepcion)
        MOVE.B          #%00010101,CRA      * Activamos transmision y recepcion para A
        MOVE.B          #%00010101,CRB      * Activamos transmision y recepcion para B
		MOVE.B			#%01000000,IVR	    * Estableces vector de Interrupcion 40(Hex)
		MOVE.B			#%00100010,IMR	    * Habilitar interrupciones de recepcion en A y B. Inhibidas transmisiones
		MOVE.B			#%00100010,COPIA_IMR * Actualiza copia de IMR
		MOVE.L 			#RTI,$100           * Inicio de RTI en tabla de interrupciones
		MOVE.B 			#0,(N_CHAR_A)       * Numero de caracteres leidos en A = 0
        MOVE.B 			#0,(N_CHAR_B)       * Numero de caracteres leidos en B = 0
		
* INICIALIZA BUFFERS	

        MOVE.L #0,A0                	    * A0 = 0
        MOVE.L #A_BUF_SCAN,A_INI_SCAN       * inicializo puntero de inicio SCAN de linea A con dir del buffer SCAN A
        MOVE.L #A_BUF_SCAN,A_LEC_SCAN       * inicializo puntero de lectura SCAN de linea A con dir del buffer SCAN A
        MOVE.L #A_BUF_SCAN,A_ESC_SCAN       * inicializo puntero de escritura SCAN de linea A con dir del buffer SCAN A
        MOVE.L #A_BUF_SCAN,A0         	    * A0 = dir buffer SCAN A
        ADDA.L #2000,A0             	    * A0 = dir buffer SCAN A + 2000
        MOVE.L A0,A_FIN_SCAN           	    * calculamos posicion final del puntero a partir de la inicial sumando 2000

        MOVE.L #0,A0                	    * A0 = 0
        MOVE.L #B_BUF_SCAN,B_INI_SCAN       * inicializo puntero de inicio SCAN de linea B con dir del buffer SCAN B
        MOVE.L #B_BUF_SCAN,B_LEC_SCAN       * inicializo puntero de lectura SCAN de linea B con dir del buffer SCAN B
        MOVE.L #B_BUF_SCAN,B_ESC_SCAN       * inicializo puntero de escritura SCAN de linea B con dir del buffer SCAN B
        MOVE.L #B_BUF_SCAN,A0         	    * A0 = dir buffer SCAN B
        ADDA.L #2000,A0             	    * A0 = dir buffer SCAN B + 2000
        MOVE.L A0,B_FIN_SCAN           	    * calculamos posicion final del puntero a partir de la inicial sumando 2000
 
        MOVE.L #0,A0                	    * A0 = 0
        MOVE.L #A_BUF_PRINT,A_INI_PRINT     * inicializo puntero de inicio PRINT de linea A con dir del buffer PRINT A
        MOVE.L #A_BUF_PRINT,A_LEC_PRINT     * inicializo puntero de lectura PRINT de linea A con dir del buffer PRINT A
        MOVE.L #A_BUF_PRINT,A_ESC_PRINT     * inicializo puntero de escritura PRINT de linea A con dir del buffer PRINT A
        MOVE.L #A_BUF_PRINT,A0         	    * A0 = dir buffer PRINT A
        ADDA.L #2000,A0             	    * A0 = dir buffer PRINT A + 2000
        MOVE.L A0,A_FIN_PRINT            	* calculamos posicion final del puntero a partir de la inicial sumando 2000

        MOVE.L #0,A0                    	* A0=0.
        MOVE.L #B_BUF_PRINT,B_INI_PRINT     * inicializo puntero de inicio PRINT de linea B con dir del buffer PRINT B
        MOVE.L #B_BUF_PRINT,B_LEC_PRINT     * inicializo puntero de lectura PRINT de linea B con dir del buffer PRINT B
        MOVE.L #B_BUF_PRINT,B_ESC_PRINT     * inicializo puntero de escritura PRINT de linea B con dir del buffer PRINT B
        MOVE.L #B_BUF_PRINT,A0         	    * A0 = dir buffer PRINT B
        ADDA.L #2000,A0             	    * A0 = dir buffer PRINT B + 2000
        MOVE.L A0,B_FIN_PRINT           	* calculamos posicion final del puntero a partir de la inicial sumando 2000

        ANDI.W #$2000,SR             	    * activa modo supervisor e interrupciones.
		MOVE.L #0,A0                    	* A0=0.
        RTS                         	    * retorno.
		
		
************************************************************************
******************************** LEECAR ********************************
************************************************************************

* En D0 esta el parametro de entrada: buffer bit 0: 0 linea A  	1 linea B
*                                            bit 1: 0 recepcion 1 transmision
* Si vacio devuelve 0xFFFFFFFF y no modifica
* Si no extraer primer caracter del buffer seleccionado y almacenar en D0
* Eliminar primer caracter
* Escribir en D0 valor de retorno 0-255

LEECAR		LINK     A6,#-24          * creamos el marco de pila 8B para guardar 2 registros de 4B.
			MOVE.L   A1,-4(A6)        * salvamos el registro A1
			MOVE.L   A2,-8(A6)        * salvamos el registro A2
			CMP.B    #0,D0            * comprobamos descriptor
			BEQ      LEEC_RA          * si descriptor = 0 saltamos a LEEC_RA
			CMP.B    #1,D0            * comprobamos descriptor
			BEQ      LEEC_RB          * si descriptor = 1 saltamos a LEEC_RB
			CMP.B    #2,D0            * comprobamos descriptor
			BEQ      LEEC_TA          * si descriptor = 2 saltamos a LEEC_TA
			CMP.B    #3,D0            * comprobamos descriptor
			BEQ      LEEC_TB          * si descriptor = 3 saltamos a LEEC_TB
			MOVE.L   #$ffffffff,D0    * en otro caso error ponemos D0 = H'FFFFFFFF.
			
FIN_LEEC	MOVE.L   -4(A6),A1        * restauramos el registro A1
			MOVE.L   -8(A6),A2        * restauramos el registro A2
			UNLK     A6               * destruimos marco de pila.
			RTS                       * retorno.

***************************************************************************
* LLEEC_RA (lectura del caracter)
* ILEEC_RA (reiniciar puntero de lectura a inicio de buffer de lectura)
***************************************************************************

LEEC_RA		MOVE.L   A_LEC_SCAN,A1    * A1 = puntero de lectura.
			MOVE.L   A_ESC_SCAN,A2    * A2 = puntero de escritura.
			
			CMP.L A1,A2               * comparamos A1 y A2.
			BEQ VLEEC_RA	     	  * si son iguales no podemos leer dato, saltamos a VLEEC_RA.
			
LLEEC_RA	MOVE.B (A1),D0            * leemos dato y guardamos en D0
			CMP.L A_FIN_SCAN,A1       * comparamos A1 y puntero final buffer.
			BEQ ILEEC_RA              * si son iguales tenemos que posicionar el puntero de lectura el comienzo del buffer, para ello saltamos.
			ADD.L #1,A1               * si son distintos incrementamos el puntero de lectura A1.
			
FLEEC_RA 	MOVE.L A1,A_LEC_SCAN      * guardamos el la posicion del puntero de lectura.
			JMP FIN_LEEC              * salto a fin de LEECAR.
			
VLEEC_RA	MOVE.L   #$ffffffff,D0	  * el buffer esta vacio
			JMP FIN_LEEC              * salto a fin de LEECAR.

ILEEC_RA	MOVE.L A_INI_SCAN,A1      * A1 = puntero de inicio de buffer.
			JMP FLEEC_RA 
			
***************************************************************************
* LLEEC_RB (lectura del caracter)
* ILEEC_RB (reiniciar puntero de lectura a inicio de buffer de lectura)
***************************************************************************

LEEC_RB		MOVE.L   B_LEC_SCAN,A1    * A1 = puntero de lectura.
			MOVE.L   B_ESC_SCAN,A2    * A2 = puntero de escritura.
			
			CMP.L A1,A2               * comparamos A1 y A2.
			BEQ VLEEC_RB              * si son iguales no podemos leer dato, saltamos a VLEEC_RB.
			
LLEEC_RB    MOVE.B (A1),D0            * leemos dato y guardamos en D0
			CMP.L B_FIN_SCAN,A1       * comparamos A1 y puntero final buffer.
			BEQ ILEEC_RB              * si son iguales poner el puntero de lectura el comienzo del buffer, para ello saltamos.
			ADD.L #1,A1               * si son distintos incrementamos el puntero de lectura A1.
			
FLEEC_RB	MOVE.L A1,B_LEC_SCAN      * guardamos la posicion del puntero de lectura.
			JMP FIN_LEEC              * salto a fin de LEECAR.
			
VLEEC_RB	MOVE.L   #$ffffffff,D0	  * el buffer esta vacio
			JMP FIN_LEEC              * salto a fin de LEECAR.

ILEEC_RB	MOVE.L B_INI_SCAN,A1      * A1 = puntero de inicio de buffer.
			JMP FLEEC_RB 
			
***************************************************************************
* LLEEC_TA (lectura del caracter)
* ILEEC_TA (reiniciar puntero de lectura a inicio de buffer de lectura)
***************************************************************************

LEEC_TA		MOVE.L   A_LEC_PRINT,A1   * A1 = puntero de lectura.
			MOVE.L   A_ESC_PRINT,A2   * A2 = puntero de escritura.
			
			CMP.L A1,A2               * comparamos A1 y A2.
			BEQ VLEEC_TA         	  * si son iguales no podemos leer dato, saltamos a VLEEC_TA.
			
LLEEC_TA 	MOVE.B (A1),D0            * leemos dato y guardamos en D0
			CMP.L A_FIN_PRINT,A1      * comparamos A1 y puntero final buffer.
			BEQ ILEEC_TA              * si son iguales poner el puntero de lectura el comienzo del buffer, para ello saltamos.
			ADD.L #1,A1               * si son distintos incrementamos el puntero de lectura A1.
			
FLEEC_TA    MOVE.L A1,A_LEC_PRINT     * guardamos la posicion del puntero de lectura.
			JMP FIN_LEEC           	  * salto a fin de LEECAR.
			
VLEEC_TA	MOVE.L   #$ffffffff,D0	  * el buffer esta vacio
			JMP FIN_LEEC              * salto a fin de LEECAR.

ILEEC_TA	MOVE.L A_INI_PRINT,A1     * A1 = puntero de inicio de buffer.
			JMP FLEEC_TA 
			
***************************************************************************
* LLEEC_TB (lectura del caracter)
* LEEC_TB (reiniciar puntero de lectura a inicio de buffer de lectura)
***************************************************************************

LEEC_TB	    MOVE.L   B_LEC_PRINT,A1   * A1 = puntero de lectura.
			MOVE.L   B_ESC_PRINT,A2   * A2 = puntero de escritura.
			
			CMP.L A1,A2               * comparamos A1 y A2.
			BEQ VLEEC_TB              * si son iguales no podemos leer dato, saltamos a VLEEC_TB.
			
LLEEC_TB	MOVE.B (A1),D0            * leemos dato y guardamos en D0
			CMP.L B_FIN_PRINT,A1      * comparamos A1 y puntero final buffer.
			BEQ ILEEC_TB           	  * si son iguales poner el puntero de lectura el comienzo del buffer, para ello saltamos.
			ADD.L #1,A1               * si son distintos incrementamos el puntero de lectura A1.
			
FLEEC_TB	MOVE.L A1,B_LEC_PRINT     * guardamos el la posicion del puntero de lectura.
			JMP FIN_LEEC              * salto a fin de LEECAR.
			
VLEEC_TB	MOVE.L   #$ffffffff,D0	  * el buffer esta vacio
			JMP FIN_LEEC              * salto a fin de LEECAR.

ILEEC_TB	MOVE.L B_INI_PRINT,A1     * A1 = puntero de inicio de buffer.
			JMP FLEEC_TB 	
	
************************************************************************
******************************** ESCCAR ********************************
************************************************************************
* En D0 esta el parametro de entrada: buffer bit 0: 0 linea A  	1 linea B
*                                            bit 1: 0 recepcion 1 transmision
* Caracter a escribir en 8 bits menos significativos de D1
* Si buffer lleno devuelve 0xFFFFFFFF en D0
* Si ok devuelve 0 en D0

ESCCAR		LINK     A6,#-24          * creamos el marco de pila 8B para guardar 2 registros de 4B.
			MOVE.L   A1,-4(A6)        * salvamos el registro A1
			MOVE.L   A2,-8(A6)        * salvamos el registro A2
			CMP.B    #0,D0            * comprobamos descriptor
			BEQ      ESCC_RA          * si descriptor = 0 saltamos a ESCC_RA
			CMP.B    #1,D0            * comprobamos descriptor
			BEQ      ESCC_RB          * si descriptor = 1 saltamos a ESCC_RB
			CMP.B    #2,D0            * comprobamos descriptor
			BEQ      ESCC_TA          * si descriptor = 2 saltamos a ESCC_TA
			CMP.B    #3,D0            * comprobamos descriptor
			BEQ      ESCC_TB          * si descriptor = 3 saltamos a ESCC_TB
			MOVE.L   #$ffffffff,D0    * en otro caso error ponemos D0 = H'FFFFFFFF.
FIN_ESCC	MOVE.L   -4(A6),A1        * restauramos el registro A1
			MOVE.L   -8(A6),A2        * restauramos el registro A2
			UNLK     A6               * destruimos marco de pila.
			RTS                       * retorno.
		
***************************************************************************

ESCC_RA		MOVE.L   A_LEC_SCAN,A1    * A1 = puntero de lectura.
			MOVE.L   A_ESC_SCAN,A2    * A2 = puntero de escritura.
			
			MOVE.B D1,(A2)            * Inserta el dato en la posicion de escritura (8bits menos significat.)
			CMP.L A_FIN_SCAN,A2       * comparamos A2 y puntero final buffer.
			BEQ IESCC_RA           	  * si son iguales salto a IESCC_RA
			ADD.L #1,A2               * si son distintos incrementamos el puntero de ESCRITURA A2.
			CMP.L A1,A2               * comparamos puntero de lectura y escritura.
			BEQ LLESC_RA	          * si son iguales salta a LLESC_RA
			
FESCC_RA	MOVE.L   #0,D0			  * escribe 0 en D0 (operacion correcta)
			MOVE.L A2,A_ESC_SCAN      * guardamos el la posicion del puntero de escritura.
			JMP FIN_ESCC   
			 
LLESC_RA	SUB.L #1,A2    			  * vuelve el puntero una posicion atras(se pierde lo insertado)
			MOVE.L   #$ffffffff,D0	  * escribe H'FFFFFFFF en D0 (buffer lleno)
			MOVE.L A2,A_ESC_SCAN      * guardamos el la posicion del puntero de escritura.
			JMP FIN_ESCC		
			
IESCC_RA	MOVE.L A_INI_SCAN,A2      * A2 <- puntero de inicio de buffer.
			CMP.L A1,A2               * comparamos puntero de lectura y escritura.
			BEQ VESCC_RA           	  * si son iguales salta a VESCC_RA
			JMP FESCC_RA		
			
VESCC_RA    MOVE.L A_FIN_SCAN,A2      * A2 <- puntero de fin de buffer.
			MOVE.L   #$ffffffff,D0	  * escribe H'FFFFFFFF en D0 (buffer lleno)
			MOVE.L A2,A_ESC_SCAN      * guardamos el la posicion del puntero de escritura.
			JMP FIN_ESCC
		 
***************************************************************************

ESCC_RB		MOVE.L   B_LEC_SCAN,A1    * A1 = puntero de lectura.
			MOVE.L   B_ESC_SCAN,A2    * A2 = puntero de escritura.
			
			MOVE.B D1,(A2)            * Inserta el dato en la posicion de escritura (8bits menos significat.)
			CMP.L B_FIN_SCAN,A2       * comparamos A2 y puntero final buffer.
			BEQ IESCC_RB              * si son iguales salto a IESCC_RB
			ADD.L #1,A2               * si son distintos incrementamos el puntero de ESCRITURA A2.
			CMP.L A1,A2               * comparamos puntero de lectura y escritura.
			BEQ LLESC_RB	          * si son iguales salta a LLESC_RB
			
FESCC_RB	MOVE.L   #0,D0			  * escribe 0 en D0 (operacion correcta)
			MOVE.L A2,B_ESC_SCAN      * guardamos la posicion del puntero de escritura.
			JMP FIN_ESCC   
			 
LLESC_RB 	SUB.L #1,A2    			  * vuelve el puntero una posicion atras(se pierde lo insertado)
			MOVE.L   #$ffffffff,D0	  * escribe H'FFFFFFFF en D0 (buffer lleno)
			MOVE.L A2,B_ESC_SCAN      * guardamos  la posicion del puntero de escritura.
			JMP FIN_ESCC		
			
IESCC_RB	MOVE.L B_INI_SCAN,A2      * A2 <- puntero de inicio de buffer.
			CMP.L A1,A2               * comparamos puntero de lectura y escritura.
			BEQ VESCC_RB              * si son iguales salta a VESCC_RB
			JMP FESCC_RB		
			
VESCC_RB 	MOVE.L B_FIN_SCAN,A2      * A2 <- puntero de fin de buffer.
			MOVE.L   #$ffffffff,D0	  * escribe H'FFFFFFFF en D0 (buffer lleno)
			MOVE.L A2,B_ESC_SCAN      * guardamos la posicion del puntero de escritura.
			JMP FIN_ESCC
			
***************************************************************************

ESCC_TA		MOVE.L   A_LEC_PRINT,A1   * A1 = puntero de lectura.
			MOVE.L   A_ESC_PRINT,A2   * A2 = puntero de escritura.
			
			MOVE.B D1,(A2)            * Inserta el dato en la posicion de escritura (8bits menos significat.)
			CMP.L A_FIN_PRINT,A2      * comparamos A2 y puntero final buffer.
			BEQ IESCC_TA              * si son iguales salto a IESCC_TA
			ADD.L #1,A2               * si son distintos incrementamos el puntero de ESCRITURA A2.
			CMP.L A1,A2               * comparamos puntero de lectura y escritura.
			BEQ LLESC_TA           	  * si son iguales salta a LLESC_TA
			
FESCC_TA	MOVE.L   #0,D0			  * escribe 0 en D0 (operacion correcta)
			MOVE.L A2,A_ESC_PRINT     * guardamos la posicion del puntero de escritura.
			JMP FIN_ESCC   
			 
LLESC_TA 	SUB.L #1,A2    			  * vuelve el puntero una posicion atras(se pierde lo insertado)
			MOVE.L   #$ffffffff,D0	  * escribe H'FFFFFFFF en D0 (buffer lleno)
			MOVE.L A2,A_ESC_PRINT     * guardamos  la posicion del puntero de escritura.
			JMP FIN_ESCC				
			
IESCC_TA	MOVE.L A_INI_PRINT,A2     * A2 <- puntero de inicio de buffer.
			CMP.L A1,A2               * comparamos puntero de lectura y escritura.
			BEQ VESCC_TA              * si son iguales salta a VESCC_TA
			JMP FESCC_TA		
			
VESCC_TA 	MOVE.L A_FIN_PRINT,A2     * A2 <- puntero de fin de buffer.
			MOVE.L   #$ffffffff,D0	  * escribe H'FFFFFFFF en D0 (buffer lleno)
			MOVE.L A2,A_ESC_PRINT     * guardamos la posicion del puntero de escritura.
			JMP FIN_ESCC
			
			
***************************************************************************

ESCC_TB		MOVE.L  B_LEC_PRINT,A1    * A1 = puntero de lectura.
			MOVE.L   B_ESC_PRINT,A2   * A2 = puntero de escritura.
			
			MOVE.B D1,(A2)            * Inserta el dato en la posicion de escritura (8bits menos significat.)
			CMP.L B_FIN_PRINT,A2      * comparamos A2 y puntero final buffer.
			BEQ IESCC_TB              * si son iguales salto a IESCC_TB
			ADD.L #1,A2               * si son distintos incrementamos el puntero de ESCRITURA A2.
			CMP.L A1,A2               * comparamos puntero de lectura y escritura.
			BEQ LLESC_TB           	  * si son iguales salta a LLESC_TB
			
FESCC_TB	MOVE.L   #0,D0			  * escribe 0 en D0 (operacion correcta)
			MOVE.L A2,B_ESC_PRINT     * guardamos el la posicion del puntero de escritura.
			JMP FIN_ESCC   
			 
LLESC_TB 	SUB.L #1,A2    			  * vuelve el puntero una posicion atras(se pierde lo insertado)
			MOVE.L   #$ffffffff,D0	  * escribe H'FFFFFFFF en D0 (buffer lleno)
			MOVE.L A2,B_ESC_PRINT     * guardamos la posicion del puntero de escritura.
			JMP FIN_ESCC			
			
IESCC_TB	MOVE.L B_INI_PRINT,A2     * A2 <- puntero de inicio de buffer.
			CMP.L A1,A2               * comparamos puntero de lectura y escritura.
			BEQ VESCC_TB              * si son iguales salta a VESCC_TB
			JMP FESCC_TB		
			
VESCC_TB 	MOVE.L B_FIN_PRINT,A2     * A2 <- puntero de fin de buffer.
			MOVE.L   #$ffffffff,D0	  * escribe H'FFFFFFFF en D0 (buffer lleno)
			MOVE.L A2,B_ESC_PRINT     * guardamos la posicion del puntero de escritura.
			JMP FIN_ESCC

			
************************************************************************
******************************** SCAN **********************************
************************************************************************

SCAN    	LINK     A6,#-24          * creamos el marco de pila 24B para guardar 6 registros de 4B.
			MOVE.L   A3,-4(A6)        * salvamos los registros que vamos a usar A3, D4, D5. A1, A2 y D6 
			MOVE.L   D4,-8(A6)        * 
			MOVE.L   D5,-12(A6)       *
			MOVE.L   A1,-16(A6)       *  
			MOVE.L   A2,-20(A6)       *
			MOVE.L   D6,-24(A6)       *
			MOVE.L   8(A6),A3         * A3 direccion del buffer.
			MOVE.W   12(A6),D5        * D5 descriptor.
			MOVE.W   14(A6),D4        * D4 tamaño.	
			CMP.W 	 #0,D4			  * si tamaño es 0 salto SCANZ 
			BEQ 	 SCANZ
			MOVE.L   #0,D2            * contador = 0.
			CMP.W    #0,D5            * comprobamos descriptor.
			BEQ      SCAN_A           * si descriptor = 0 saltamos a SCAN_A.
			CMP.W    #1,D5
			BEQ      SCAN_B           * si descriptor = 1 saltamos a SCAN_B.
			MOVE.L   #$ffffffff,D0    * en otro caso error ponemos D0 = H'FFFFFFFF.
			JMP 	 FIN_SCAN
SCANZ		MOVE.L   #0,D0
FIN_SCAN	MOVE.L   -4(A6),A3        * restauramos los registros que hemos usado A3, D4, D5. A1, A2 y D6 
			MOVE.L   -8(A6),D4        *
			MOVE.L   -12(A6),D5       *
			MOVE.L   -16(A6),A1       *
			MOVE.L   -20(A6),A2       *
			MOVE.L   -24(A6),D6       *
			UNLK     A6               * destruimos marco de pila.
			RTS                       * retorno.
			
			
************************************************************************
****************************** SCAN_A **********************************
************************************************************************
* D4=tamaño(numero max de caracteres a leer y copiar) D5=descriptor(A o B), A3=direccion del buffer.
* D0= salida, numero de caracteres leidos y copiados, D2 = contador

SCAN_A     	MOVE.L   #0,D0 		    * parametro de entrada de LEECAR es 0(buffer A de recepcion)
			BSR 	 LEECAR		    * lee 1 dato y lo pone en D0
			MOVE.L   #$ffffffff,D6	 
			CMP.L 	 D0,D6 			* comprueba si D0 tiene codigo error, entonces salto a F_SCANA
			BEQ      F_SCANA			
			
			ADD.L #1,D2             * incrementamos contador.
			MOVE.B D0,(A3)+         * copiamos el dato leido en el buffer y aumentamos su direccion.
			CMP.L D2,D4             * comparamos nº de datos leidos (D2) con tamaño D4.
			BNE SCAN_A	            * si no son iguales bucle a SCAN_A
				
			MOVE.L   D2,D0 		    * copia datos leidos (D2 en el registro de resultado D0)
			JMP FIN_SCAN            * salto a fin de SCAN
			
F_SCANA		MOVE.L   D2,D0			* no se ha leido ningun caracter (buffer vacio)
			JMP FIN_SCAN			* salto a fin de SCAN
							
************************************************************************
****************************** SCAN_B **********************************
************************************************************************
* D4=tamaño(numero max de caracteres a leer y copiar, D5=descriptor(A o B), A3=direccion del buffer.
* D0= salida, numero de caracteres leidos y copiados, D2 = contador

SCAN_B     	MOVE.L   #1,D0 		    * parametro de entrada de LEECAR es 1(buffer B de recepcion)
			BSR 	 LEECAR		  	* lee 1 dato y lo pone en D0
			MOVE.L   #$ffffffff,D6	 
			CMP.L 	 D0,D6 			* comprobar si D0 tiene codigo error, entonces salto a F_SCANB
			BEQ      F_SCANB
			
			ADD.L #1,D2             * incrementamos contador.
			MOVE.B D0,(A3)+         * copiamos el dato leido en el buffer y aumentamos su direccion.
			CMP.L D2,D4             * comparamos nº de datos leidos (D2) con tamaño D4.
			BNE SCAN_B	            * si no son iguales seguimos y si no fin. 
			
			MOVE.L   D2,D0 		    * copia datos leidos (D2 en el registro de resultado D0)
			JMP FIN_SCAN            * salto a fin de SCAN.
			
F_SCANB		MOVE.L   D2,D0			* Ponemos en D0 el numero de caracteres leidos hasta ahora
			JMP FIN_SCAN			* salto a fin de SCAN
				
************************************************************************
******************************** PRINT *********************************
************************************************************************
* A3 = Direccion Buffer 	D4 = Tamaño     D5 = Descriptor(0 -linea A, 1 -linea B)
* Lee del buffer y escribe en puerto A o B
* D0 = Si error en parametros FF.. si no error indica num de caracteres aceptados

PRINT    	LINK     A6,#-28          * creamos el marco de pila 28B para guardar 7 registros de 4B.
			MOVE.L   A3,-4(A6)        * salvamos los registros que vamos a usar A3, D4, D5, A1, A2, D3 y D2 
			MOVE.L   D4,-8(A6)        * 
			MOVE.L   D5,-12(A6)       *
			MOVE.L   A1,-16(A6)       *  
            MOVE.L   A2,-20(A6)       *
			MOVE.L   D3,-24(A6)		  *
			MOVE.L   D2,-28(A6)		  *
			MOVE.L   8(A6),A3         * A3 direccion del buffer.
			MOVE.W   12(A6),D5        * D5 descriptor.
			MOVE.W   14(A6),D4        * D4 tamaño.
			CMP.W 	 #0,D4			  * si tamaño es 0 salto a PRINTZ 
			BEQ 	 PRINTZ
			MOVE.L   #0,D2            * contador (D2) = 0.
			CMP.W    #0,D5            * comprobamos descriptor.
			BEQ      PRINT_A          * si descriptor = 0 saltamos a PRINT_A.
			CMP.W    #1,D5
			BEQ      PRINT_B          * si descriptor = 1 saltamos a PRINT_B.
			MOVE.L   #$ffffffff,D0    * en otro caso error ponemos D0 = H'FFFFFFFF.
			JMP 	 FIN_PRINT
PRINTZ		MOVE.L   #0,D0	
FIN_PRINT	MOVE.L   -4(A6),A3        * restauramos los registros que hemos usado A3, D4, D5, A1, A2, D3 y D2
			MOVE.L   -8(A6),D4        *
			MOVE.L   -12(A6),D5       *
			MOVE.L   -16(A6),A1       *
			MOVE.L   -20(A6),A2       *
			MOVE.L   -24(A6),D3       *
			MOVE.L   -28(A6),D2       *
			UNLK     A6               * destruimos marco de pila.
			RTS                       * retorno.
			
************************************************************************
****************************** PRINT_A *********************************
************************************************************************
* D4=tamaño, D5=descriptor, A3=direccion del buffer

PRINT_A    	MOVE.B (A3)+,D1            	 * parametro de entrada de ESCCAR (caracter a escribir)
			MOVE.L   #2,D0 		         * parametro de entrada de ESCCAR es 2(buffer A de transmision)
			*MOVE.W SR,D3                * guardamos SR
            *MOVE.W #9984,SR             * desactivamos INT en SR
			BSR ESCCAR		  	         * escribe 1 dato y lo pone en D0
			CMP.L #0,D0					 * comprueba que D0 es 0 (escritura de caracter correcta)	
            BNE FA_PRINT				 * si no son iguales salto a FA_PRINT
			
            ADD.L #1,(N_CHAR_A)         * incrementamos el numero de caracteres que faltan por transmitir.
            *MOVE.W D3,SR               * volvemos a poner SR en su estado anterior.
            ADD.L #1,D2                 * incrementamos contador.
            CMP.L D2,D4                 * comparamos contador con tamaño.
            BEQ FA_PRINT                * si son iguales saltamos a final.
            JMP PRINT_A                 * si no seguimos escribiendo.  

FA_PRINT    MOVE.L D2,D0				* D0 = numero de caracteres escritos(contador)
			CMP.L #0,(N_CHAR_A)         * comparamos la variable N_CHAR_A con 0.
            BEQ FIN_PRINT        	    * si es asi nos vamos a fin si activas interrupciones.
            MOVE.B COPIA_IMR,D5         * si no copiamos en D5 IMR
            BSET #0,D5            	    * activamos las interrupciones por linea A 
            MOVE.B D5,COPIA_IMR         * guardamos IMR (modificado) en variable
            MOVE.B D5,IMR               * modificamos registro IMR
            JMP	FIN_PRINT        	    * salto a fin	

************************************************************************
****************************** PRINT_B *********************************
************************************************************************
* D4=tamaño, A3=direccion del buffer.

PRINT_B    	MOVE.B (A3)+,D1            	 * parametro de entrada de ESCCAR (caracter a escribir)
			MOVE.L   #3,D0 		         * parametro de entrada de ESCCAR es 3(buffer B de transmision)
			*MOVE.W SR,D3                * guardamos SR
			*MOVE.W #9984,SR             * desactivamos INT en SR
			BSR ESCCAR		  	         * escribe 1 dato y resultado en D0
			CMP.L #0,D0					 * comprueba que D0 es 0 (escritura de caracter correcta)
            BNE FB_PRINT				 * si no son iguales salto a FB_PRINT
			
            ADD.L #1,(N_CHAR_B)          * incrementamos el numero de caracteres que faltan por transmitir.
            *MOVE.W D3,SR                * volvemos a poner SR en su estado anterior.
            ADD.L #1,D2                  * incrementamos contador.
            CMP.L D2,D4                  * comparamos contador con tamaño.
            BEQ FB_PRINT                 * si son iguales saltamos a final.
            JMP PRINT_B                  * si no seguimos escribiendo. 

FB_PRINT   	MOVE.L D2,D0				 * D0 = numero de caracteres escritos(contador)
			CMP.L #0,(N_CHAR_B)          * comparamos la variable N_CHAR_B con 0.
            BEQ FIN_PRINT        	     * si N_CHAR_B es 0 salto a FIN_PRINT
            MOVE.B COPIA_IMR,D5          * si N_CHAR_B no es 0 copiamos en D5 IMR
            BSET #4,D5                   * activamos las interrupciones por linea B 
            MOVE.B D5,COPIA_IMR          * guardamos IMR (modificado) en variable
            MOVE.B D5,IMR                * modificamos registro IMR
            JMP	FIN_PRINT        	     * salto a fin				

************************************************************************
********************************** RTI *********************************
************************************************************************				

			
RTI    		LINK     A6,#-24      	    * creamos el marco de pila 24B para guardar 6 registros de 4B.
			MOVE.L   D2,-4(A6)     	    * salvamos los registros que vamos a usar
			MOVE.L   D5,-8(A6)
			MOVE.L   A0,-12(A6)
			MOVE.L   A1,-16(A6)
			MOVE.L   A2,-20(A6)
			MOVE.L   D0,-24(A6)
			MOVE.B   ISR,D5         	* copiamos ISR en D5
			MOVE.B   COPIA_IMR,D2       * y la copia de IMR en D2
			AND.B    D2,D5         		* haciendo un and entre ambos se consigue saber el periferico que interrumpe
			BTST     #1,D5
			BNE      RECEP_A         	* si el bit 1 RxRDYA/FFULLA esta a 1 saltamos a recepcion por linea A
			BTST     #5,D5
			BNE      RECEP_B       	    * si el bit 5 RxRDYB/FFULLB esta a 1 saltamos a recepcion por linea B
			BTST     #0,D5
			BNE      TRANS_A         	* si el bit 0 TxRDYA esta a 1 saltamos a transmision por linea A
			BTST     #4,D5
			BNE      TRANS_B          	* si el bit 4 TxRDYB esta a 1 saltamos a transmision por linea A
FIN_RTI 	MOVE.L   -4(A6),D2     		* restauramos los registros que hemos usado
			MOVE.L   -8(A6),D5
			MOVE.L   -12(A6),A0
			MOVE.L   -16(A6),A1
			MOVE.L   -20(A6),A2
			MOVE.L   -24(A6),D0
			UNLK     A6             	* destruimos marco de pila.
			RTE                     	* retorno.
			
************************************************************************
************************ TRANSMISION POR LINEA A ***********************
************************************************************************			

TRANS_A     MOVE.L   #2,D0 		   			* parametro de entrada de LEECAR es 2(buffer A de transmision)
			BSR LEECAR		    	    	* lee 1 dato y lo pone en D0 
			
			MOVE.L  #$ffffffff,A1	
			CMP.L A1,D0 					* si D0 es ffffffff deshabilitar interrupciones de transmision linea A
			BEQ TRANS_AD
				
			MOVE.B D0,TBA           		* el caracter leido lo pasamos al registro del buffer de transmision TBA.
            SUB.L #1,(N_CHAR_A)       		* decrementamos el numero de caracteres que faltan por transmitir.
            CMP.L #0,(N_CHAR_A)       		* comparamos el numero de caracteres que faltan por transmitir con 0.
            BNE FIN_RTI      	      		* si son distintos saltamos a fin
            MOVE.B COPIA_IMR,D2         	*
            BCLR #0,D2                		* ponemos a 0 el bit 0 de IMR, es decir desactivamos la interrupcion.
            MOVE.B D2,COPIA_IMR         	* modificamos la copia de IMR
            MOVE.B D2,IMR             		* y modificamos IMR
            JMP FIN_RTI               		* saltamos a fin.

TRANS_AD	BCLR #0,D2                		* ponemos a 0 el bit 0 de IMR, es decir desactivamos la interrupcion.
            MOVE.B D2,COPIA_IMR         	* modificamos la copia de IMR
            MOVE.B D2,IMR             		* y modificamos IMR
            JMP FIN_RTI               		* saltamos a fin.		
			
************************************************************************
************************ RECEPCION POR LINEA A *************************
************************************************************************

RECEP_A 	EOR.L D1,D1               		* D1 = 0.
            MOVE.B RBA,D1             		* llevamos el registro de buffer de recepcion de A a D1			
			MOVE.L   #0,D0 		            * parametro de entrada de ESCCAR es 0(buffer A de recepcion)
			BSR ESCCAR		  	            * escribe el dato en el buffer		
            JMP FIN_RTI              		* salto a FIN_RTI.
			
************************************************************************
************************ TRANSMISION POR LINEA B ***********************
************************************************************************			

TRANS_B     MOVE.L   #3,D0 		   			* parametro de entrada de LEECAR es 3(buffer B de transmision)
			BSR LEECAR		    	    	* lee 1 dato y lo pone en D0 
											
			MOVE.L  #$ffffffff,A1	
			CMP.L A1,D0 					* si D0 es ffffffff deshabilitar interrupciones de transmision linea B
			BEQ TRANS_BD

			MOVE.B D0,TBB           		* el caracter leido lo pasamos al registro del buffer de transmision TBB.
            SUB.L #1,(N_CHAR_B)       		* decrementamos el numero de caracteres que faltan por transmitir.
            CMP.L #0,(N_CHAR_B)       		* comparamos el numero de caracteres que faltan por transmitir con 0.
            BNE FIN_RTI      	      		* si son distintos saltamos a fin
            MOVE.B COPIA_IMR,D2         	
            BCLR #4,D2                		* ponemos a 0 el bit 4 de IMR, es decir desactivamos la interrupcion.
            MOVE.B D2,COPIA_IMR         	* modificamos la copia de IMR
            MOVE.B D2,IMR             		* y modificamos IMR
            JMP FIN_RTI               		* saltamos a fin.
			
TRANS_BD    BCLR #4,D2                		* ponemos a 0 el bit 4 de IMR, es decir desactivamos la interrupcion.
            MOVE.B D2,COPIA_IMR         	* modificamos la copia de IMR
            MOVE.B D2,IMR             		* y modificamos IMR
            JMP FIN_RTI               		* saltamos a fin.

************************************************************************
************************ RECEPCION POR LINEA B *************************
************************************************************************

RECEP_B 	EOR.L D1,D1               		* D1 = 0.
            MOVE.B RBB,D1             		* llevamos el registro de buffer de recepcion de A a D1
			MOVE.L   #1,D0 		            * parametro de entrada de ESCCAR es 1(buffer B de recepcion)
			BSR ESCCAR		  	            * escribe el dato en el buffer
            JMP FIN_RTI              		* salto a FIN_RTI.
			
************************************************************************
*********************************** PPAL *******************************
************************************************************************


PPAL   		MOVE.L  #$8000,A7
			MOVE.L  #$0,D0
			MOVE.L  #$0,D1
			MOVE.L  #$0,D2
			MOVE.L  #$0,D3
			MOVE.L  #$0,D4
			MOVE.L  #$0,D5
			MOVE.L  #$0,D6
			MOVE.L  #$0,D7
			MOVE.L  #$0,A0
			MOVE.L  #$0,A1
			MOVE.L  #$0,A2
			MOVE.L  #$0,A3
			MOVE.L  #$0,A4
			MOVE.L  #$0,A5
			MOVE.L  #$0,A6
      		
BUFFER: 	DS.B 2100 					* Buffer para lectura y escritura de caracteres
PARDIR: 	DC.L 0 						* Direccion que se pasa como parametro
PARTAM: 	DC.W 0 						* Tamaño que se pasa como parametro
CONTC:  	DC.W 0 						* Contador de caracteres a imprimir
DESA:   	EQU 0 						* Descriptor linea A
DESB:   	EQU 1 						* Descriptor linea B
TAMBS:  	EQU 4 						* Tamaño de bloque para SCAN
TAMBP:  	EQU 4 						* Tamaño de bloque para PRINT	

* Manejadores de excepciones
INICIO: 	MOVE.L  #BUS_ERROR,8 		* Bus error handler
			MOVE.L  #ADDRESS_ER,12 		* Address error handler
			MOVE.L  #ILLEGAL_IN,16 		* Illegal instruction handler
			MOVE.L  #PRIV_VIOLT,32 		* Privilege violation handler
			MOVE.L  #ILLEGAL_IN,40 		* Illegal instruction handler
			MOVE.L  #ILLEGAL_IN,44 		* Illegal instruction handler
			
			BSR INIT
			MOVE.W #$2000,SR 			* Permite interrupciones
		
BUCPR:  	MOVE.W #TAMBS,PARTAM 		* Inicializa parametro de tamaño
			MOVE.L #BUFFER,PARDIR 		* Parametro BUFFER = comienzo del buffer
OTRAL:  	MOVE.W PARTAM,-(A7) 		* Tamaño de bloque
			MOVE.W #DESB,-(A7) 			* Puerto A
			MOVE.L PARDIR,-(A7) 		* Direccion de lectura
ESPL:  		BSR SCAN
			ADD.L #8,A7 				* Restablece la pila
			ADD.L D0,PARDIR 			* Calcula la nueva direccion de lectura
			SUB.W D0,PARTAM 			* Actualiza el numero de caracteres leidos
			BNE OTRAL 					* Si no se han leido todas los caracteres del bloque se vuelve a leer
			MOVE.W #TAMBS,CONTC 		* Inicializa contador de caracteres a imprimir
			MOVE.L #BUFFER,PARDIR 		* Parametro BUFFER = comienzo del buffer
OTRAE:  	MOVE.W #TAMBP,PARTAM 		* Tamaño de escritura = Tamaño de bloque
ESPE:   	MOVE.W PARTAM,-(A7) 		* Tamaño de escritura
			MOVE.W #DESA,-(A7) 			* Puerto B
			MOVE.L PARDIR,-(A7) 		* Direccion de escritura
			BSR PRINT
			ADD.L #8,A7					* Restablece la pila
			ADD.L D0,PARDIR 			* Calcula la nueva direccion del buffer
			SUB.W D0,CONTC 				* Actualiza el contador de caracteres
			BEQ SALIR 					* Si no quedan caracteres se acaba
			SUB.W D0,PARTAM 			* Actualiza el tamano de escritura
			BNE ESPE 					* Si no se ha escrito todo el bloque se insiste
			CMP.W #TAMBP,CONTC 			* Si el no de caracteres que quedan es menor que el tama~no establecido se imprime ese n´umero
			BHI OTRAE 					* Siguiente bloque
			MOVE.W CONTC,PARTAM
			BRA ESPE 					* Siguiente bloque
SALIR:  	BRA BUCPR
BUS_ERROR:  BREAK 						* Bus error handler
			NOP
ADDRESS_ER: BREAK 						* Address error handler
			NOP
ILLEGAL_IN: BREAK 						* Illegal instruction handler
			NOP
PRIV_VIOLT: BREAK 						* Privilege violation handler
			NOP
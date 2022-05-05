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
ACR    EQU $effc09	     * control auxiliar
IMR    EQU $effc0B       * mascara de interrupcion A (escritura)
ISR    EQU $effc0B       * estado de interrupcion A (lectura)

MR1B   EQU $effc11       * modo B (escritura)
MR2B   EQU $effc11       * modo B (2 escritura)
CRB    EQU $effc15	     * control A (escritura)
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

** BUFERES INTERNOS
SCAN_A  EQU     0
SCAN_B  EQU     1
PRNT_A  EQU     2
PRNT_B  EQU     3

TAMBUF  EQU     2001
R
* Buffer de Scan A
BSCAN_A         DC.L    BSC_A   * Puntero de extraccion
                DC.L    BSC_A   * Puntero de insercion
BSC_A           DS.B    TAMBUF  * BUFFER DE 2001 BYTES

* Buffer de Scan B
BSCAN_B         DC.L    BSC_B   * Puntero de extraccion
                DC.L    BSC_B   * Puntero de insercion
BSC_B           DS.B    TAMBUF  * BUFFER DE 2001 BYTES

* Buffer de Print A
BPRNT_A         DC.L    BPR_A   * Puntero de extraccion
                DC.L    BPR_A   * Puntero de insercion
BPR_A           DS.B    TAMBUF  * BUFFER DE 2001 BYTES

* Buffer de Print B
BPRNT_B         DC.L    BPR_B   * Puntero de extraccion
                DC.L    BPR_B   * Puntero de insercion
BPR_B           DS.B    TAMBUF  * BUFFER DE 2001 BYTES

                DC.W 1
                
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
                        


                        BSR      INI_BUFS

** Inicializacion de los contadores a cero y reseteo de A0
                        MOVE.L    #0,D0
                        MOVE.L    #0,A0
                        RTS
*************************** FIN INI **************************************************



*************************** INI_BUFS *************************************************
INI_BUFS:
                        MOVE.L  #BSC_A,BSCAN_A          * Inicia el puntero de extraccion
                        MOVE.L  #BSC_A,BSCAN_A+4        * Inicia el puntero de insercion
                        MOVE.L  #BSC_B,BSCAN_B          * Inicia el puntero de extraccion
                        MOVE.L  #BSC_B,BSCAN_B+4        * Inicia el puntero de insercion
                        MOVE.L  #BPR_A,BPRNT_A          * Inicia el puntero de extraccion
                        MOVE.L  #BPR_A,BPRNT_A+4        * Inicia el puntero de insercion
                        MOVE.L  #BPR_B,BPRNT_B          * Inicia el puntero de extraccion
                        MOVE.L  #BPR_B,BPRNT_B+4        * Inicia el puntero de insercion

                        RTS
*************************** FIN INI_BUFS *********************************************


*************************** ESCCAR *********************************************************

ESCCAR:
        MOVEM.L A0-A4/D2,-(A7)       * Guarda todos los registros en la pila

        CMP.L   #SCAN_A,D0
        BNE     ESCB
        MOVE.L  #BSCAN_A,A0
        BRA     CONTESC
ESCB:   CMP.L   #SCAN_B,D0
        BNE     EPRA
        MOVE.L  #BSCAN_B,A0
        BRA     CONTESC
EPRA:   CMP.L   #PRNT_A,D0
        BNE     EPRB
        MOVE.L  #BPRNT_A,A0
        BRA     CONTESC
EPRB:   MOVE.L  #BPRNT_B,A0

CONTESC: EOR.L D0,D0            * A0 contiene la direcci�n del puntero de extracci�n
        MOVE.L  (A0),A1         * A1 contiene el puntero de extracci�n
        MOVE.L  4(A0),A2        * A2 contiene el puntero de inserci�n
		        MOVE.L  A0,A3
        ADD.L   #8,A3           * A3 contiene el comienzo del buffer
        MOVE.L  A3,D2
        ADD.L   #TAMBUF,D2
        MOVE.L  D2,A4           * A4 contiene el final del buffer (1 m�s all�)

        MOVE.B  D1,(A2)+                * Inserta el caracter
        CMP.L   A2,A4           * Si son iguales  ha llegado al final del buffer
        BNE     ACPUNE
        MOVE.L  A3,A2           * Se pone el puntero de inserci�n al comienzo del buffer
ACPUNE: CMP.L   A1,A2           * Si son iguales se ha llenado el buffer
        BEQ     LLENO
        MOVE.L  A2,4(A0)        * Actualiza el puntero de inserci�n
        BRA     FINEB
LLENO:  MOVE.L  #-1,D0          * Se devuelve un -1 en D0
FINEB:  MOVEM.L       (A7)+,A0-A4/D2 *Restauramos los registros
        RTS

*************************** FIN ESCCAR *****************************************************


*************************** LEECAR *********************************************************

LEECAR:
        MOVEM.L A0-A4/D2,-(A7)       * Guarda todos los registros en la pila

        CMP.L   #SCAN_A,D0
        BNE     LSCB
        MOVE.L  #BSCAN_A,A0
        BRA     CONTLEE
LSCB:   CMP.L   #SCAN_B,D0
        BNE     LPRA
        MOVE.L  #BSCAN_B,A0
        BRA     CONTLEE
LPRA:   CMP.L   #PRNT_A,D0
        BNE     LPRB
        MOVE.L  #BPRNT_A,A0
        BRA     CONTLEE
LPRB:   MOVE.L  #BPRNT_B,A0

CONTLEE:                        * A0 contiene la direcci�n del puntero de extracci�n
        MOVE.L  (A0),A1         * A1 contiene el puntero de extracci�n
        MOVE.L  4(A0),A2        * A2 contiene el puntero de inserci�n
        MOVE.L  A0,A3
        ADD.L   #8,A3           * A3 contiene el comienzo del buffer
        MOVE.L  A3,D2
        ADD.L   #TAMBUF,D2
        MOVE.L  D2,A4           * A4 contiene el final del buffer (1 m�s all�)

        CMP.L   A1,A2           * Si son iguales, el buffer est� vac�o
        BNE     NOVAC
        MOVE.L  #-1,D0
        BRA     SALLB

NOVAC:  MOVE.B  (A1)+,D0                * Extrae el caracter
        CMP.L   A1,A4           * Si son iguales  ha llegado al final del buffer
        BNE     ACPUNL
        MOVE.L  A3,A1           * Se pone el puntero de extracci�n al comienzo del buffer
ACPUNL: MOVE.L  A1,(A0)         * Actualiza el puntero de extracci�n

SALLB:  MOVEM.L (A7)+,A0-A4/D2 *Restauramos los registros
        RTS

*************************** FIN LEECAR *****************************************************

*************************** SCAN *****************************************************
** Lee los caracteres que entran y los copia al buffer indicado
* Llama a LEECAR
* 
SCAN:
                        LINK A6,#-36
                        MOVEM.L	A0-A5/D1-D5,-(A6)

                        ** Reset de parámetros
                        CLR         D0          * * RETURN (0XFFFFFFFF O NUMERO DE CARACTERES ACEPTADOS PARA LECTURA)
                        CLR         D1
                        CLR         D2
                        CLR         D3
                        CLR         D4
                        CLR         D5
                        MOVE.L      8(A6),A1        * DIR BUFFER A A1
                        MOVE.L      12(A6),D1       * DESCRIPTOR A D1
                        MOVE.L      14(A6),D2       * TAMAÑO A D2
                        MOVE.L      D1,D5           * HAGO UNA COPIA DE D1 PARA USARLA DESPUES 

                        **COMPROBACIÓN DE TAMAÑO**
                        CMP.W       D2,D0           * aprovecho que D0 está limpio para comprobar el tamaño
                        BLE         FN_SCN          * si el tamaño es menor o igual a 0 me voy al final

                        MOVE.L      #$FFFFFFFF,D4   * D4 = -1 para casos y comprobaciones

                        **SELECCION DE BUFFER**
                        CMP.W       #0,D1
                        BEQ         SA              *LEER POR A 
                        CMP.W       #1,D1
                        BEQ         SB              *ESCRIBIR POR B

                        **ERROR EN CARACTER**
                        MOVE.L      D4,D0 
                        BRA         FN_SCN

                        **LECTURA**
        
        SA:             CMP.L       D2,D3           * He leido todo?
                        BEQ         FN_SCN          * Si -> fin
                        BSR         LEECAR          * D0=0 luego llamo a leecar sin problemas
                        CMP.L       D0,D4           * Buffer vacio? (D0=FFFFFFFF?) 
                        BEQ         FN_SCN          * Si -> fin
                        MOVE.B      D0,(A5)+        * mover a buffer incrementando puntero
                        ADD.L       #1,D3           * incremento contador de caracteres leidos
                        BRA         SA

        SB:             CMP.L       D2,D3           * SI SE HA LEIDO TODO -> FIN
                        MOVE.L      D1,D0           * D0=descriptor     
                        BSR         LEECAR     
                        CMP.L       D0,D4           * Buffer vacio? (D0=FFFFFFFF?)
                        BEQ         FN_SCN          * Si -> fin
                        MOVE.B      D0,(A5)+        * mover a buffer incrementando puntero
                        ADD.L       #1,D3           * incremento contador de caracteres leidos
                        BRA         SB 

                        **FIN SCAN** 

        FN_SCN:         MOVE.L D3,D0                * D0<-contador de caracteres leidos 
                        MOVEM.L	(A6)+,A0-A5/D1-D5                    
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
                        LINK A6,#-36
                        MOVEM.L	A0-A5/D1-D5,-(A6)
                        ** RESET DE PARAMETROS Y LECTURA DE PARAMETROS(BUFFER(ireccion) 8,DESCRIPTOR(Dato) 12,TAMAÑO(dato) 16)**
                        CLR         D0              * RETURN (0XFFFFFFFF O NUMERO DE CARACTERES ACEPTADOS PARA ESCRITURA)
                        CLR         D1
                        CLR         D2
                        CLR         D4
                        CLR         D6
                        MOVE.L     8(A6),A1        * DIR BUFFER A A1
                        MOVE.L     12(A6),D1       * DESCRIPTOR A D1
                        MOVE.L      D1,D6          * HAGO UNA COPIA DE D1 PARA USARLA DESPUES 
                        MOVE.L     14(A6),D2       * TAMAÑO A D2
                        MOVE.L      D2,D3           * COPIO EL TAMAÑO EN D3
                        **SELECCION DE BUFFER**
                        CMP.W       #0,D1
                        BEQ         PA              *ESCRIBIR POR A 
                        CMP.W       #1,D1
                        BEQ         PB              *ESCRIBIR POR B
                        **ERROR EN CARACTER**
                        MOVE.L      #$FFFFFFFF,D0 
                        BRA         FN_PRNT
                        **ESCRITURA**
        PA:             CMP.L       #0,D3           * SI SE HA ESCRITO TODO -> FIN
                        BEQ         FINP
                        MOVE        D1,D4
                        MOVE        (A1)+,D1        * COPIAMOS EN D1 EL BUFFER
                        MOVE.L      #2,D0           * ESCCAR ESRIBA POR LTA
                        BSR         ESCCAR 
                        CMP.L       #$FFFFFFFF,D0   * MIRAMOS SI ESCCAR HA FALLADO SI?-> FIN
                        BEQ         FINP 
                        MOVE.L      D4,D1    
                        SUB.L       #1,D3
                        ADD.L       #1,D5
                        BRA         PA

        PB:             CMP.L       #0,D3           * SI SE HA ESCRITO TODO -> FIN
                        BEQ         FINP
                        MOVE        D0,D4
                        MOVE.L      (A1)+,D1        * COPIAMOS EN D1 EL BUFFER
                        MOVE.L      #3,D0           * ESCCAR ESRIBA POR LTB
                        BSR         ESCCAR 
                        CMP.L       #$FFFFFFFF,D0   
                        BEQ         FINP
                        MOVE.L      D4,D0     
                        SUB.L       #1,D3
                        ADD.L       #1,D5
                        BRA         PB

        FINP:           CLR         D1
                        MOVE.L      D6,D1           * CARGO EN D1 EL VALOR QUE TENIA AL PRINCIPIO  
                        CMP         #0,D5
                        BEQ         FN_PRNT
                        CMP.W       #0,D1
                        BEQ         IPA               
                        CMP.W       #1,D1
                        BEQ         IPB   
                        **INTERRUPCIONES**
        IPA:            MOVE.B      IMRDUP,D4
                        BSET        #0,D4
                        MOVE.B      D4,IMRDUP
                        MOVE.B      D4,IMR 
                        BRA         FN_PRNT

        IPB:            MOVE.B      IMRDUP,D4
                        BSET        #4,D4
                        MOVE.B      D4,IMRDUP
                        MOVE.B      D4,IMR 
                        BRA         FN_PRNT
                        **FIN PRINT** 
        FN_PRNT:        MOVE.L D3,D0
                        MOVEM.L	(A6)+,A0-A5/D1-D5                    
                        UNLK A6
                        RTS
*************************** FIN PRINT *****************************************************
*************************** RTI ****************************************************
RTI:
        RTS

*************************** FIN RTI ****************************************************
**************************** PROGRAMA PRINCIPAL ********************************

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

OTRAL:  MOVE.W PARTAM,-(A7) * Tama~no de bloque
        MOVE.W #DESA,-(A7) * Puerto A
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
        MOVE.W #DESB,-(A7) * Puerto B
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
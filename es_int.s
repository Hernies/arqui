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


** BUFERES INTERNOS
SCAN_A  EQU     0
SCAN_B  EQU     1
PRNT_A  EQU     2
PRNT_B  EQU     3

TAMBUF  EQU     2001

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
                        MOVE.L    #RTI,$100           * Inserta dir de RTI en primer vector int


                        BR      INI_BUFS

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


*************************** SCAN *****************************************************



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
                    **SELECCION DE BUFFER**
                    CMP.W       #0,D1
                    BEQ         PA              *ESCRIBIR POR A 
                    CMP.W       #1,D1
                    BEQ         PB              *ESCRIBIR POR B
                    **ERROR EN CARACTER**
                    MOVE.L      #$FFFFFFFF,D0 
                    BRA         FN_PRNT
                    **ESCRITURA**
     PA:            MOVE.L      D2,D3           * COPIO EL TAMAÑO EN D3
    BPA:            CMP.L       #0,D3           * SI SE HA ESCRITO TODO -> FIN
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
                    BR          PA
           
     PB:            MOVE.L      D2,D3           * COPIO EL TAMAÑO EN D3
    BPB:            CMP.L       #0,D3           * SI SE HA ESCRITO TODO -> FIN
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
                    BR          PB

    FINP:           CLR         D1
                    MOVE.L      D6,D1           * CARGO EN D1 EL VALOR QUE TENIA AL PRINCIPIO  
                    CMP         #0,D5
                    BEQ         FIN_PRNT
                    CMP.W       #0,D1
                    BEQ         IPA               
                    CMP.W       #1,D1
                    BEQ         IPB   
                    **INTERRUPCIONES**
    IPA:            MOVE.B      IMRDUP,D4
                    BSET        #0,D4
                    MOVE.B      D4,IMRDUP
                    MOVE.B      D4, IMR 
                    BRA         FN_PRNT

    IPB:            MOVE.B      IMRDUP,D4
                    BSET        #4,D4
                    MOVE.B      D4,IMRDUP
                    MOVE.B      D4, IMR 
                    BRA         FN_PRNT
                    **FIN PRINT** 
    FN_PRNT:        MOVE.L D5,D0
                    MOVEM.L	(A6)+,A0-A5/D1-D5                    
                    UNLK A6
                    RTS

*************************** FIN PRINT *****************************************************


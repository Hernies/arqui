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
**************************** INIT ********************************************

INIT:
* inicializamos líneas de comunicaciones


*************************** INI_BUFS *********************************************************

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

*************************** FIN INI_BUFS *****************************************************
** Escribe en un bufer interno (de tamaño 2000) de manera no bloqueante (acaba cuando termina de escribir Buffer)
* Llama a ESCCAR
* Devuelve el numero de caracteres copiados en D0
* puntero de pila tiene que estar igual que al principio (LINK u ULINK)
                    ****** RECUERDA ****** 
                        *   An -> REGISTRO DE DIRECCIONES 
                        *   Dn -> REGISTRO DE DATOS

PRINT:
                    LINK A6,#-36
                    MOVEM.L	A0-A5/D1-D3,-(A6)
                    ** RESET DE PARAMETROS Y LECTURA DE PARAMETROS(BUFFER(ireccion) 8,DESCRIPTOR(Dato) 12,TAMAÑO(dato) 16)**
                    CLR     D0  
                    CLR     D1
                    CLR     D2

                    **SELECCION DE BUFFER**

                    **ERROR EN CARACTER**

                    **INTERRUPCIONES**

                    **FIN PRINT** 

                    MOVEM.L	(A6)+,A0-A5/D1-D3                    
                    UNLK A6



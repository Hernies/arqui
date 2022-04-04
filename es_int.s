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

* 0 ENTRADA A
BEA:        DS.B    TAMBUF      * Bufer Entrada A
PIEA:       DC.L    0           * Puntero Inicio Entrada A
PFEA:       DC.L    0           * Puntero Fin Entrada A


* 1 ENTRADA B
BEB:        DS.B    TAMBUF      * Bufer Entrada B
PIEB:       DC.L    0           * Puntero Inicio Entrada B
PFEB:       DC.L    0           * Puntero Fin Entrada B


* 2 SALIDA A
BSA:        DS.B    TAMBUF  	* Bufer Salida A
PISA:       DC.L    0           * Puntero Inicio Salida A
PFSA:       DC.L    0           * Puntero Fin Salida A


* 2 SALIDA B
BSB:        DS.B    TAMBUF  	* Bufer Salida A
PISB:       DC.L    0           * Puntero Inicio Salida A
PFSB:       DC.L    0           * Puntero Fin Salida A


**************************** INIT ********************************************
INIT:
* inicializamos líneas de comunicaciones


**************************** INIT_BUFS ********************************************

INIT_BUFS:

**************************** PRINT ********************************************
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



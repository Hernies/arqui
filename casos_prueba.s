************************** COMUN A TODOS ***********************************************************************************
INICIO: 
    MOVE.L #BUS_ERROR,8 * Bus error handler
    MOVE.L #ADDRESS_ER,12 * Address error handler
    MOVE.L #ILLEGAL_IN,16 * Illegal instruction handler
    MOVE.L #PRIV_VIOLT,32 * Privilege violation handler
    MOVE.L #ILLEGAL_IN,40 * Illegal instruction handler
    MOVE.L #ILLEGAL_IN,44 * Illegal instruction handler
    BSR INIT
    MOVE.W #$2000,SR * Permite interrupciones
    BUCPR: 

    SALIR: BRA BUCPR
************************** FIN COMUN A TODOS ***********************************************************************************

************************** ESCCAR Y LEECAR **********************************************************************************
        
*        BSR     INIT
*        MOVE.B  #%01,D0 * Writing to receptor B ($BD1)
*        MOVE.B  #$5,D1  * caracter
*        BSR     ESCCAR
*        MOVE.B  #%01,D0 * Writing to receptor B ($BD1)
*        MOVE.B  #$6,D1  * caracter
*        BSR     ESCCAR
*        MOVE.B  #%01,D0 * Writing to receptor B ($BD1)
*        MOVE.B  #$7,D1  * caracter
*        BSR     ESCCAR   
*        MOVE.B  #%01,D0 * Reading from receptor B
*        BSR     LEECAR
*        MOVE.B  #%01,D0 * Reading from receptor B
*        BSR     LEECAR
*        MOVE.B  #%01,D0 * Reading from receptor B
*        BSR     LEECAR
*        BREAK

************************** FIN ESCCAR Y LEECAR **********************************************************************************

************************** SCAN **********************************************************************************
**** Caso 7.
* DESC_C7:    EQU 1
* TAM_C7:     EQU 15

* Test con 30 chars
* 32000: 0x00, 0x00, 0x23, 0x6d     0x236d =>   9069
* 32004: 0x00, 0x01,                01 =>       Linea B
* 32006: 0x00, 0x0F,                0x0F =>     Tamano = 15
*  0x236d:                            15 Chars leidos van aqui

    MOVE.W #TAM_C7,PARTAM        * Inicializa par´ametro de tama~no
    MOVE.L #BUFFER,PARDIR       * Parametro BUFFER = comienzo del buffer $236D
    BUCPR: 
        MOVE.W PARTAM,-(A7)     * Tama~no de bloque
        MOVE.W #DESC_C7,-(A7)      * Puerto A
        MOVE.L PARDIR,-(A7)     * Direccion de lectura
        BSR SCAN
        ADD.L #8,A7             * Restablece la pila
        ADD.L D0,PARDIR         * Calcula la nueva direcci´on de lectura
    SALIR: BRA BUCPR

**** Caso SCAN_1.
* DESC_CS1:   EQU 0
* TAM_CS1:    EQU 1900

* Test con 1900 chars
* 32000: 0x00, 0x00, 0x23, 0x6d     0x236d =>   9069
* 32004: 0x00, 0x00,                00 =>       Linea A
* 32006: 0x07, 0x6C,                0x76C =>     Tamano = 1900
* 0x236d:                           1900 Chars leidos van aqui

    MOVE.W #TAM_CS1,PARTAM        * Inicializa par´ametro de tama~no
    MOVE.L #BUFFER,PARDIR       * Parametro BUFFER = comienzo del buffer $236D
    BUCPR: 
        MOVE.W PARTAM,-(A7)     * Tama~no de bloque
        MOVE.W #DESC_CS1,-(A7)      * Puerto A
        MOVE.L PARDIR,-(A7)     * Direccion de lectura
        BSR SCAN
        ADD.L #8,A7             * Restablece la pila
        ADD.L D0,PARDIR         * Calcula la nueva direcci´on de lectura
    SALIR: BRA BUCPR

**** Caso SCAN_2.
* DESC_CS2:   EQU 0
* TAM_CS2:    EQU 2100

* Test con 2100 chars
* 32000: 0x00, 0x00, 0x23, 0x6d     0x236d =>   9069
* 32004: 0x00, 0x00,                00 =>       Linea A
* 32006: 0x08, 0x34,                0x834 =>     Tamano = 2100
* 0x236d:                           2000 Chars leidos van aqui

    MOVE.W #TAM_CS2,PARTAM      * Inicializa parametro de tamano
    MOVE.L #BUFFER,PARDIR       * Parametro BUFFER = comienzo del buffer $236D
    BUCPR: 
        MOVE.W PARTAM,-(A7)     * Tamano de bloque
        MOVE.W #DESC_CS2,-(A7)      * Puerto A
        MOVE.L PARDIR,-(A7)     * Direccion de lectura
        BSR SCAN
        ADD.L #8,A7             * Restablece la pila
        ADD.L D0,PARDIR         * Calcula la nueva direcci´on de lectura
    SALIR: BRA BUCPR

* D0 = 0x7d0
* 236d: 2000 chars

**** Caso SCAN_3.
* DESC_CS3:   EQU 0
* TAM_CS3:    EQU 100

* Test con 450 chars
* 32000: 0x00, 0x00, 0x23, 0x6d     0x236d =>   9069
* 32004: 0x00, 0x00,                00 =>       Linea A
* 32006: 0x00, 0x0F,                0x0F =>     Tamano = 100
* 0x236d:                           450 Chars leidos van aqui

    MOVE.W #TAM_CS3,PARTAM      * Inicializa parametro de tamano
    MOVE.L #BUFFER,PARDIR       * Parametro BUFFER = comienzo del buffer $236D
    BUCPR: 
        MOVE.W PARTAM,-(A7)     * Tamano de bloque
        MOVE.W #DESC_CS3,-(A7)      * Puerto A
        MOVE.L PARDIR,-(A7)     * Direccion de lectura
        BSR SCAN
        ADD.L #8,A7             * Restablece la pila
        ADD.L D0,PARDIR         * Calcula la nueva direcci´on de lectura
    SALIR: BRA BUCPR
*Run SCAN 1
* D0 = 0x64
* 236d: 100 chars
*Run SCAN 2
* D0 = 0x64
* 236d: 200 chars
*Run SCAN 3
* D0 = 0x64
* 236d: 300 chars
*Run SCAN 4
* D0 = 0x64
* 236d: 400 chars
*Run SCAN 5
* D0 = 0x32
* 236d: 50 chars

**** Caso SCAN_4.
* DESC_CS4:   EQU 0
* TAM_CS4:    EQU 5

* Test con 20 chars
* 32000: 0x00, 0x00, 0x23, 0x6d     0x236d =>   9069
* 32004: 0x00, 0x00,                00 =>       Linea A
* 32006: 0x00, 0x05,                0x05 =>     Tamano = 5
* 0x236d:                           20 Chars leidos van aqui

    MOVE.W #TAM_CS4,PARTAM      * Inicializa parametro de tamano
    MOVE.L #BUFFER,PARDIR       * Parametro BUFFER = comienzo del buffer $236D
    BUCPR: 
        MOVE.W PARTAM,-(A7)     * Tamano de bloque
        MOVE.W #DESC_CS4,-(A7)      * Puerto A
        MOVE.L PARDIR,-(A7)     * Direccion de lectura
        BSR SCAN
        ADD.L #8,A7             * Restablece la pila
        ADD.L D0,PARDIR         * Calcula la nueva direcci´on de lectura
    SALIR: BRA BUCPR
*Run SCAN 1
* D0 = 0x5
* 236d: 5 chars
*Run SCAN 2
* D0 = 0x5
* 236d: 10 chars
*Run SCAN 3
* D0 = 0x5
* 236d: 15 chars
*Run SCAN 4
* D0 = 0x5
* 236d: 20 chars
*Run SCAN 5
* D0 = 0x0
* 236d: 20 chars


************************** FIN SCAN **********************************************************************************

************************** PRINT **********************************************************************************

**** Caso PRINT_1.
* DESC_CP1:   EQU 0
* TAM_CCP1:    EQU 5

* Test con 20 chars en el buffer    
* 32000: 0x00, 0x00, 0x23, 0x6d     0x236d =>   9069
* 32004: 0x00, 0x01,                00 =>       Linea B
* 32006: 0x00, 0x05,                0x0f =>     Tamano = 15
* 0x236d:                           20 Chars leidos aqui y posteriormente para PRINT

    BUCPR: 
        MOVE.W #TAM_C7,PARTAM        * Inicializa par´ametro de tama~no
        MOVE.L #BUFFER,PARDIR       * Par´ametro BUFFER = comienzo del buffer $236D
        OTRAL: 
            MOVE.W PARTAM,-(A7)     * Tama~no de bloque
            MOVE.W #DESC_C7,-(A7)      * Puerto B
            MOVE.L PARDIR,-(A7)     * Direcci´on de lectura
            ESPL: BSR SCAN
            ADD.L #8,A7             * Restablece la pila
            ADD.L D0,PARDIR         * Calcula la nueva direcci´on de lectura
            SUB.W D0,PARTAM         * Actualiza el n´umero de caracteres le´ıdos
            BNE OTRAL               * Si no se han le´ıdo todas los caracteres
        * del bloque se vuelve a leer
        
        MOVE.W #TAM_C7,CONTC         * Inicializa contador de caracteres a imprimir
        MOVE.L #BUFFER,PARDIR       * Par´ametro BUFFER = comienzo del buffer
        OTRAE: MOVE.W #TAM_CCP1,PARTAM * Tama~no de escritura = Tama~no de bloque
        ESPE: MOVE.W PARTAM,-(A7)   * Tama~no de escritura
        MOVE.W #DESC_CP1,-(A7)          * Puerto A
        MOVE.L PARDIR,-(A7)         * Direcci´on de escritura
        BSR PRINT
        ADD.L #8,A7                 * Restablece la pila
        ADD.L D0,PARDIR             * Calcula la nueva direcci´on del buffer
        SUB.W D0,CONTC              * Actualiza el contador de caracteres
        BEQ SALIR                   * Si no quedan caracteres se acaba
        SUB.W D0,PARTAM             * Actualiza el tama~no de escritura
        BNE ESPE                    * Si no se ha escrito todo el bloque se insiste
        CMP.W #TAM_CCP1,CONTC          * Si el no de caracteres que quedan es menor que
        * el tama~no establecido se imprime ese n´umero
        BHI OTRAE                   * Siguiente bloque
        MOVE.W CONTC,PARTAM
        BRA ESPE                    * Siguiente bloque
        SALIR: BRA BUCPR



* Breakpoint despues de SCAN 1
* D0 = 0xf
* 236d(BUFFER): 15 chars
* bd1(BR):      15 chars

* Breakpoint despues de PRINT 1
* D0 = 0x5
* 13a2(AT):     5 chars

* Breakpoint despues de PRINT 2
* D0 = 0x5
* 13a2(AT):     10 chars

* Breakpoint despues de PRINT 3
* D0 = 0x5
* 13a2(AT):     15 chars

* Breakpoint despues de SCAN 1
* D0 = 0x5
* 236d(BUFFER): 5 chars
* bd1(BR):      15 chars


************************** FIN PRINT **********************************************************************************

* el del pdf
* TAMBS: EQU 30 * Tamano de bloque para SCAN
* TAMBP: EQU 7 * Tamano de bloque para PRINT

        * Manejadores de excepciones
INICIO: 
    MOVE.L #BUS_ERROR,8   * Bus error handler
    MOVE.L #ADDRESS_ER,12 * Address error handler
    MOVE.L #ILLEGAL_IN,16 * Illegal instruction handler
    MOVE.L #PRIV_VIOLT,32 * Privilege violation handler
    MOVE.L #ILLEGAL_IN,40 * Illegal instruction handler
    MOVE.L #ILLEGAL_IN,44 * Illegal instruction handler
    BSR INIT
    MOVE.W #$2000,SR * Permite interrupciones
    BUCPR: 
        MOVE.W #TAMBS,PARTAM        * Inicializa par´ametro de tama~no
        MOVE.L #BUFFER,PARDIR       * Par´ametro BUFFER = comienzo del buffer $236D
        OTRAL: 
            MOVE.W PARTAM,-(A7)     * Tama~no de bloque
            MOVE.W #DESA,-(A7)      * Puerto A
            MOVE.L PARDIR,-(A7)     * Direcci´on de lectura
            ESPL: BSR SCAN
            ADD.L #8,A7             * Restablece la pila
            ADD.L D0,PARDIR         * Calcula la nueva direcci´on de lectura
            SUB.W D0,PARTAM         * Actualiza el n´umero de caracteres le´ıdos
            BNE OTRAL               * Si no se han le´ıdo todas los caracteres
        * del bloque se vuelve a leer

        MOVE.W #TAMBS,CONTC         * Inicializa contador de caracteres a imprimir
        MOVE.L #BUFFER,PARDIR       * Par´ametro BUFFER = comienzo del buffer
        OTRAE: MOVE.W #TAMBP,PARTAM * Tama~no de escritura = Tama~no de bloque
        ESPE: MOVE.W PARTAM,-(A7)   * Tama~no de escritura
        MOVE.W #DESB,-(A7)          * Puerto B
        MOVE.L PARDIR,-(A7)         * Direcci´on de escritura
        BSR PRINT
        ADD.L #8,A7                 * Restablece la pila
        ADD.L D0,PARDIR             * Calcula la nueva direcci´on del buffer
        SUB.W D0,CONTC              * Actualiza el contador de caracteres
        BEQ SALIR                   * Si no quedan caracteres se acaba
        SUB.W D0,PARTAM             * Actualiza el tama~no de escritura
        BNE ESPE                    * Si no se ha escrito todo el bloque se insiste
        CMP.W #TAMBP,CONTC          * Si el no de caracteres que quedan es menor que
        * el tama~no establecido se imprime ese n´umero
        BHI OTRAE                   * Siguiente bloque
        MOVE.W CONTC,PARTAM
        BRA ESPE                    * Siguiente bloque
        SALIR: BRA BUCPR
    

        *BSR is used to call a procedure or a subroutine. Since it provides relative 
        *addressing (and therefore position independent code), its use is preferable 
        *to JSR.
        *BRA is an unconditional relative jump (or goto). You use a BRA instruction 
        *to write position independent code, because the destination address (branch 
        *target address) is specified with respect to the current value of the PC. 
        *A JMP instruction does not produce position independent code.

* Breakpoint despues de SCAN 1
* D0 =  01e
* 236d: 30 chars
* 400:  30 chars

* Breakpoint despues de PRINT 1
* D0 = 0x5
* 236d: 15 chars
* 400:  30 chars
* 1b73: 0 chars

**************************** FIN PROGRAMA PRINCIPAL ******************************************











* dUNT KNOW WAT DIS IS

*BSR             INIT                * Inicia el controlador
* OTRO:   MOVE.W  	#10,-(A7)
* 	MOVE.L          #$5000,-(A7)        * Prepara la direcci�n del buffer
*         BSR             SCAN                * Recibe la linea
*         ADD.L           #6,A7               * Restaura la pila
* 	MOVE.W  	#10,-(A7)
*         MOVE.L          #$5000,-(A7)        * Prepara la direcci�n del buffer
*         BSR             PRINT               * Imprime l�nea
*         ADD.L           #6,A7               * Restaura la pila
* 	BRA		OTRO
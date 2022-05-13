* la bateria de pruebas

* Prueba para SCAN con descriptor no valido

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

PRUEBA1:MOVE.W PARTAM,-(A7)     * Tama~no de bloque
        MOVE.W #3,-(A7)         * Descriptor no valido
        MOVE.L PARDIR,-(A7)     * Direcci´on de lectura
        BSR SCAN                * Llamamos a scan 

PRUEBA2:MOVE.W #0,-(A7)     * Tama~no de bloque
        MOVE.W #1,-(A7)         * Linea B
        MOVE.L PARDIR,-(A7)     * Direcci´on de lectura
        BSR SCAN                * Llamamos a scan

PRUEBA3:MOVE.W #0,-(A7)     * Tama~no de bloque
        MOVE.W #1,-(A7)         * Linea B
        MOVE.L PARDIR,-(A7)     * Direcci´on de lectura
        BSR SCAN                * Llamamos a scan

BUS_ERROR: BREAK * Bus error handler
        NOP
ADDRESS_ER: BREAK * Address error handler
        NOP
ILLEGAL_IN: BREAK * Illegal instruction handler
        NOP
PRIV_VIOLT: BREAK * Privilege violation handler
        NOP



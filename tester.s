** Definicion de equivalencias *****************************************************
*** DUART A ***                                                                    *
MR1A        EQU     $effc01             * de modo A (escritura)                    *
MR2A        EQU     $effc01             * de modo A (2º escritura)                 *
SRA         EQU     $effc03             * de estado A (lectura)                    *
CSRA        EQU     $effc03             * de seleccion de reloj A (escritura)      *
CRA         EQU     $effc05             * de control A (escritura)                 *
TBA         EQU     $effc07             * buffer transmision A (escritura)         *
RBA         EQU     $effc07             * buffer recepcion A (lectura)             *
*** DUART B ***                                                                    *
MR1B        EQU     $effc11             * de modo B (escritura)                    *
MR2B        EQU     $effc11             * de modo B (2º escritura)                 *
SRB         EQU     $effc13             * de estado B (lectura)                    *
CSRB        EQU     $effc13             * de seleccion de reloj B (escritura)      *
CRB         EQU     $effc15             * de control B (escritura)                 *
TBB         EQU     $effc17             * buffer transmision B (escritura)         *
RBB         EQU     $effc17             * buffer recepcion B (lectura)             *
*** Registros para ambos ***                                                       *
ACR         EQU     $effc09             * de control auxiliar                      *
IMR         EQU     $effc0B             * de mascara de interrupcion               *
ISR         EQU     $effc0B             * de estado de interrupcion                *
IVR         EQU     $effc19             * del vector de interrupcion               *
************************************************************************************

** Proyecto de Arquitectura **
            ORG     $0
            DC.L    $8000               * Pila
            DC.L    MAIN                * PC
SENTINEL:   DS.L    1                   * Sentinel, para que en la traza se pueda ver mejor
                                        *   los comienzos de subrutinas...
** Declarar los buferes y variables globales necesarias para el codigo
            
            ORG     $400                * Cualquier código/bufferes debe empezar apartir de la direccion 0x400
*** Posicion actual y cantidad en los buffers ***                                  *
IPBF_RA     EQU     $000400             * Puntero de inicio en BUF_RA recepcion    *
FPBF_RA     EQU     $000402             * Puntero de final  en BUF_RA recepcion    *
SZEB_RA     EQU     $000bd4             * Final del buffer                         *
IPBF_TA     EQU     $000bd6             * Puntero de inicio en BUF_TA transmision  *
FPBF_TA     EQU     $000bd8             * Puntero de final  en BUF_TA transmision  *
SZEB_TA     EQU     $0013aa             * Final del buffer                         *
IPBF_RB     EQU     $0013ac             * Puntero de inicio en BUF_RB recepcion    *
FPBF_RB     EQU     $0013ae             * Puntero de final  en BUF_RB recepcion    *
SZEB_RB     EQU     $001b80             * Final del buffer                         *
IPBF_TB     EQU     $001b82             * Puntero de inicio en BUF_TB transmision  *
FPBF_TB     EQU     $001b84             * Puntero de final  en BUF_TB transmision  *
SZEB_TB     EQU     $002356             * Final del buffer                         *
************************************************************************************


            DC.L    $04040404           * $0400 dir ini buf(BUF_RA), $0402 count buf(BUF_RA)
            DS.B    2000                * $0404 direccion del buffer de recepcion de A
            DS.W    1                   * Tamaño del buffer
            DC.L    $0bda0bda           * $0BD4 dir ini buf(BUF_TA), $0BD6 count buf(BUF_TA)
            DS.B    2000                * $0BD8 direccion del buffer de transmision de A
            DS.W    1                   * Tamaño del buffer
            DC.L    $13b013b0           * $13A8 dir ini buf(BUF_RB), $13AA count buf(BUF_RB)
            DS.B    2000                * $13AC direccion del buffer de recepcion de B
            DS.W    1                   * Tamaño del buffer
            DC.L    $1b861b86           * $1B7C dir ini buf(BUF_TB), $1B7E count fin buf(BUF_TB)
            DS.B    2000                * $1B80 direccion del buffer de transmision de B
            DS.W    1                   * Tamaño del buffer
SAV_SR      DS.W    1                   * Para salvaguardar el SR
**SAV_SRLE    DS.W    1                   * Para salvaguardar el SR en LEECAR, ESCCAR
          * ORG     $2352
IMR_C       DS.B    1                   * Para guardar el contenido de IMR para realizar lecturas
CHAR_CR     DS.B    1                   * Variable global para comprobar si el último carácter retransmitido es <CR>
          * ORG     $2354               * Para alinearse usa las direcciones pares
**** INIT ****
INIT:       MOVE.B #%00010000,CRA       * Reinicializar puntero a MR1
            MOVE.B #%00010000,CRB       * Reinicializar puntero a MR1
            MOVE.B #%00000011,MR1A      * Uso de RxRDY y 8 bits/car
            MOVE.B #%00000011,MR1B      * Uso de RxRDY y 8 bits/car
            MOVE.B #%00000000,MR2A      * No ECO
            MOVE.B #%00000000,MR2B      * No ECO
            MOVE.B #%11001100,CSRA      * Vel = 38400b/s
            MOVE.B #%11001100,CSRB      * Vel = 38400b/s
            MOVE.B #%00000000,ACR       * Seleccionar conjunto 1
            MOVE.B #%00000101,CRA       * FullDUPLEX, transmision y recepcion
            MOVE.B #%00000101,CRB       * FullDUPLEX, transmision y recepcion
            MOVE.B #$40,IVR             * Vector de interrupcion a 0x40
            MOVE.B #%00100010,IMR_C     * Copia del IMR
            MOVE.B IMR_C,IMR            * Habilitar interrupciones de recepcion
            MOVE.L #$04040404,IPBF_RA    * Iniciar buffer RA
            MOVE.W #$0,SZEB_RA
            MOVE.L #$0bda0bda,IPBF_TA    * Iniciar buffer TA
            MOVE.W #$0,SZEB_TA
            MOVE.L #$13b013b0,IPBF_RB    * Iniciar buffer RB
            MOVE.W #$0,SZEB_RB
            MOVE.L #$1b861b86,IPBF_TB    * Iniciar buffer TB
            MOVE.W #$0,SZEB_TB
            MOVE.L #RTI,$100            * Escrbir en la tabla de vectores la RTI
            MOVE.W #0,SAV_SR            * Inicializar SAV_SR, CHAR_CR
            MOVE.B #0,CHAR_CR           * Inicializar SAV_SR, CHAR_CR
            RTS
** A0: Linea de transmision A(0) o B(1)
** A1: Buffer de recepcion(0)[R] o Buffer de transmision(1)[W]

** INIT **
INIT:       ** Codigo de testeo aqui
            RTS

** LEECAR **
LEECAR:     ** Codigo de testeo aqui
            RTS

** ESCCAR **
ESCCAR:     ** Codigo de testeo aqui
            RTS

** LINEA **
LINEA:      ** Codigo de testeo aqui
            RTS

** SCAN **
SCAN:       ** Codigo de testeo aqui
            RTS

** PRINT **
PRINT:      ** Codigo de testeo aqui
            RTS

** RTI **
RTI:        ** Codigo de testeo aqui
            RTS

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
    T1:     BSR Test_2                  * Test a LINEA
            BSR Check
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
bsr_2:      BSR LINEA
            MOVE.L 24(A7),A0        * Cargar direccion de 'DataResA'
            MOVE.L (A0),D1
            MOVE.L A7,D7
            ADD.L #4,D7
            MOVE.L D7,-(A7)         * Pasar parametro 'DirGW'
            MOVE.L D1,-(A7)         * Pasar parametro 'ObtRes'
            MOVE.L D0,-(A7)         * Pasar parametro 'ExpRes'
            BSR Act_GW              * Actualizar 'GetWell'
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


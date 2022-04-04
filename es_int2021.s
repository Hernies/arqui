* Inicializa el SP y el PC
**************************
                                  ORG       $0
                                  DC.L      $8000           * Pila
                                  DC.L      INICIO          * PC

                                  ORG       $400

* Definicion de equivalencias (tomadas de la practica)
********************************************************************************

MR1A   EQU $effc01       * de modo A (escritura)
MR2A   EQU $effc01       * de modo A (2 escritura)
SRA    EQU $effc03       * de estado A (lectura)
CSRA   EQU $effc03       * de seleccion de reloj A (escritura)
CRA    EQU $effc05       * de control A (escritura)
TBA    EQU $effc07       * buffer transmision A (escritura)
RBA    EQU $effc07       * buffer recepcion A  (lectura)
ACR    EQU $effc09	 * de control auxiliar
IMR    EQU $effc0B       * de mascara de interrupcion A (escritura)
ISR    EQU $effc0B       * de estado de interrupcion A (lectura)

MR1B   EQU $effc11       * de modo B (escritura)
MR2B   EQU $effc11       * de modo B (2 escritura)
CRB    EQU $effc15	 * de control A (escritura)
TBB    EQU $effc17       * buffer transmision B (escritura)
RBB    EQU $effc17       * buffer recepcion B (lectura)
SRB    EQU $effc13       * de estado B (lectura)
CSRB   EQU $effc13       * de seleccion de reloj B (escritura)

IVR    EQU $effc19       * Registro vector de interrupcion

CR     EQU $0D	         * Carriage Return
LF     EQU $0A	         * Line Feed
FLAGT  EQU 2	         * Flag de transmision
FLAGR  EQU 0	         * Flag de recepcion
TAMBUF EQU 2001

** VARIABLES GLOBALES **
IMRDUP                            DC.B      0     * Duplicado (legible) del IMR
*REST_A   DC.L      0       
*REST_B   DC.L      0        


** BUFERES INTERNOS CON PUNTEROS DE EXTRACCION E INSERCION
** Rx A (0)
BIRA:                             DS.B      TAMBUF 
PERA:                             DC.L      0
PIRA:                             DC.L      0

** Rx B (1)
BIRB:                             DS.B      TAMBUF 
PERB:                             DC.L      0
PIRB:                             DC.L      0

** Tx A (2)
BITA:                             DS.B      TAMBUF 
PETA:                             DC.L      0
PITA:                             DC.L      0

** Tx B (3)
BITB:                             DS.B      TAMBUF 
PETB:                             DC.L      0
PITB:                             DC.L      0 
        

**************************** INIT **********************************************
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

** Inicializacion de buferes con ptros apuntando al inicio del bufer
                                  MOVE.L    #PIRA,A0
                                  MOVE.L    #BIRA,(A0)
                                  MOVE.L    #PERA,A0
                                  MOVE.L    #BIRA,(A0)

                                  MOVE.L    #PIRB,A0
                                  MOVE.L    #BIRB,(A0)
                                  MOVE.L    #PERB,A0
                                  MOVE.L    #BIRB,(A0)

                                  MOVE.L    #PITA,A0
                                  MOVE.L    #BITA,(A0)
                                  MOVE.L    #PETA,A0
                                  MOVE.L    #BITA,(A0)

                                  MOVE.L    #PITB,A0
                                  MOVE.L    #BITB,(A0)
                                  MOVE.L    #PETB,A0
                                  MOVE.L    #BITB,(A0)

** Inicializacion de los contadores a cero y reseteo de A0
                                  MOVE.L    #0,D0
                                  MOVE.L    #0,A0

** Inicialización del registro de estado (modo supervisor, intmask 0)
**MOVE.W          #$2000,SR        

                                  RTS
**************************** FIN INIT ******************************************

**************************** LEECAR ********************************************
* leecar: lee un caracter destructivamente de un bufer interno
LEECAR:
                                  MULU      #22,D0              * offset salto 22
                                  MOVE.L    #LCSEL,A0
                                  ADD.L     D0,A0
                                  JMP       (A0)             

* El salto carga el bufer seleccionado en los registros. Cada grupo de 4 
* instrucciones tiene 22 bytes (6*3 los move, 4 el BRA). 

LCSEL:                            MOVE.L    #PIRA,A1
                                  MOVE.L    #PERA,A2
                                  MOVE.L    #BIRA,A3
                                  BRA       LCCOMUN
                                  MOVE.L    #PIRB,A1
                                  MOVE.L    #PERB,A2
                                  MOVE.L    #BIRB,A3
                                  BRA       LCCOMUN
                                  MOVE.L    #PITA,A1
                                  MOVE.L    #PETA,A2
                                  MOVE.L    #BITA,A3
                                  BRA       LCCOMUN
                                  MOVE.L    #PITB,A1
                                  MOVE.L    #PETB,A2
                                  MOVE.L    #BITB,A3
                                  BRA       LCCOMUN

** Ahora el ptro. de insercion esta en A1 y el de extraccion en A2
LCCOMUN:
                                  MOVE.L    #$FFFFFFFF,D0        * Inicializa resultado
                                  MOVE.L    (A1),A0  
                                  MOVE.L    (A2),A4
                                  CMP.L     A4,A0                * Compara punteros
                                  BEQ       LEECARFIN            * Salta al final si buf vacio
                                  MOVE.L    #0,D0                * Prepara D0 para recibir result
                                  MOVE.L    (A2),A0   
                                  MOVE.B    (A0),D0              * Escribe resultado en D0

** Comprobar si A2 esta al final del bufer
                                  MOVE.L    #TAMBUF,A0
                                  ADD.L     A3,A0
                                  ADD.L     #1,(A2)              * avanzar PE en 1
                                  MOVE.L    (A2),A1
                                  CMP.L     A1,A0
                                  BEQ       LCALFINAL
                                  BRA       LEECARFIN     
LCALFINAL:
                                  MOVE.L    A3,(A2)              * Esta al final, PE = P inic BUF
LEECARFIN:     
                                  RTS
        
**************************** ESCCAR ********************************************
* esccar: escribe un caracter en un bufer interno si hay sitio
ESCCAR:
                                  MULU      #22,D0
                                  MOVE.L    #ECSEL,A0
                                  ADD.L     D0,A0
                                  JMP       (A0)             

* El salto carga el bufer seleccionado en los registros. 

ECSEL:                            MOVE.L    #PIRA,A1
                                  MOVE.L    #PERA,A2
                                  MOVE.L    #BIRA,A3
                                  BRA       ECCOMUN
                                  MOVE.L    #PIRB,A1
                                  MOVE.L    #PERB,A2
                                  MOVE.L    #BIRB,A3
                                  BRA       ECCOMUN
                                  MOVE.L    #PITA,A1
                                  MOVE.L    #PETA,A2
                                  MOVE.L    #BITA,A3
                                  BRA       ECCOMUN
                                  MOVE.L    #PITB,A1
                                  MOVE.L    #PETB,A2
                                  MOVE.L    #BITB,A3
                                  BRA       ECCOMUN

** Ahora el ptro. de insercion esta en A1 y el de extraccion en A2
ECCOMUN:
                                  MOVE.L    #$FFFFFFFF,D0        * Inicializa resultado
                                  MOVE.L    (A1),A4              * A4 <- COPIA ptr insercion buffer
                                  MOVE.L    (A2),A2              * A2 <- ptr extraccion buffer

                                  MOVE.L    #TAMBUF,A0           * A0 <- tamano buffer      
                                  ADD.L     A3,A0                * A0 <- tamano buffer + dir(buffer)
                                  ADD.L     #1,A4                * sig pos de buffer
                                  CMP.L     A4,A0                * ¿fin de buffer? 
                                  BEQ       ECALFINAL
                                  BRA       ECCONT
        
ECALFINAL:
                                  MOVE.L    A3,A4                * Esta al final, PE = P inic BUF

ECCONT:           
                                  CMP.L     A4,A2                * Compara punteros
                                  Puntero de insercion
                                  MOVE.B    D1,(A0)              * Escribe D1 en bufer
                                  BEQ       ESCCARFIN            * Salta al final si buf lleno
                                  MOVE.L    (A1),A0              *                    
                                  MOVE.L    #0,D0                * Escribe 0 en D0 = Exito
                                  MOVE.L    A4,(A1)              * Actualizar punt insercion

ESCCARFIN:     
                                  RTS

**************************** PRINT *********************************************
* inserta caracteres en bufer circular de transmision para ser transmitidos
PRINT:  
* Registros a salvar: A0-A5, D1-D3 (6+3 = 9 Registros de 4 bytes cada 1)  
                                  LINK      A6,#-36 
                                  MOVE.L    D1,-4(A6)
                                  MOVE.L    D2,-8(A6)
                                  MOVE.L    D3,-12(A6)
                                  MOVE.L    A0,-16(A6)
                                  MOVE.L    A1,-20(A6)
                                  MOVE.L    A2,-24(A6)
                                  MOVE.L    A3,-28(A6)
                                  MOVE.L    A4,-32(A6)
                                  MOVE.L    A5,-36(A6)   

* Resetear registros para copia de palabra             
                                  MOVE.L    #0,D0
                                  MOVE.L    #0,D2

* Lectura de parametros: (A6) m pila, 4(A6) dir ret, 8(A6) primer parametro
                                  MOVE.L    8(A6),A5             * Direccion del bufer (A5)
                                  MOVE.W    12(A6),D0            * Descriptor
                                  MOVE.W    14(A6),D2            * Tamaño

                                  MOVE.L    #0,D3                * D3: contador bytes copiados
         
* LINEA A
                                  CMP.W     #0,D0
                                  BEQ       PRLA
* LINEA B
                                  CMP.W     #1,D0
                                  BEQ       PRLB

*Si no es ninguno de los dos, error
                                  MOVE.L    #$FFFFFFFF,D3
                                  BRA       FINPRINT

PRLA:
                                  MOVE.L    D2,D0               * copia de tamano en D0
                                  CMP.L     D3,D0               * contador = tamano ? -> salir buc
                                  BEQ       FINPRLA
                                  MOVE.L    #2,D0               * linea trans A
                                  MOVE.B    (A5)+,D1            * copia buffer -> D1
                                  BSR       ESCCAR              * escribe en buf interno
                                  MOVE.L    #$FFFFFFFF,D1              
                                  CMP.L     D1,D0               * si error de esccar -> salida buc
                                  BEQ       FINPRLA
                                  ADD.L     #1,D3               * contador++
                                  BRA       PRLA

FINPRLA:       	
                                  MOVE.L    #0,D1
                                  CMP.L     D3,D1               * comprueba si se han copiado 0 car
                                  BEQ       FINPRINT            * si es asi no activa int

*activar interrupciones tx linea A
                                  MOVE.B    IMRDUP,D2           * D5=copia SR para restaurarlo luego
                                  BSET      #0,D2               * poner bit 0 a 1 -> habilitar TX A
                                  MOVE.B    D2,IMR              * actualiza IMR
                                  MOVE.B    D2,IMRDUP           * actualiza duplicado IMR
                                  BRA       FINPRINT
         
PRLB:
                                  MOVE.L    D2,D0               * copia de tamano en D0
                                  CMP.L     D3,D0               * contador = tamano ? -> salir buc
                                  BEQ       FINPRLB
                                  MOVE.L    #3,D0               * linea trans B
                                  MOVE.B    (A5)+,D1            * copia buffer -> D1
                                  BSR       ESCCAR              * escribe en buf interno
                                  MOVE.L    #$FFFFFFFF,D1              
                                  CMP.L     D1,D0               * si error de esccar -> salida buc
                                  BEQ       FINPRLB
                                  ADD.L     #1,D3               * contador++
                                  BRA       PRLB

FINPRLB:       	
                                  MOVE.L    #0,D1
                                  CMP.L     D3,D1               * comprueba si se han copiado 0 car
                                  BEQ       FINPRINT            * si es asi no activa int

* activar interrupciones tx linea B
                                  MOVE.B    IMRDUP,D2           * D5=copia SR para restaurarlo luego
                                  BSET      #4,D2               * poner bit 4 a 1 -> habilitar TX B
                                  MOVE.B    D2,IMR              * actualiza IMR
                                  MOVE.B    D2,IMRDUP           * actualiza duplicado IMR

FINPRINT:
                                  MOVE.L    D3,D0               * Pasar contador a resultado
                                  MOVE.L    -4(A6),D1     		
                                  MOVE.L    -8(A6),D2
                                  MOVE.L    -12(A6),D3
                                  MOVE.L    -16(A6),A0
                                  MOVE.L    -20(A6),A1
                                  MOVE.L    -24(A6),A2
                                  MOVE.L    -28(A6),A3
                                  MOVE.L    -32(A6),A4
                                  MOVE.L    -36(A6),A5
                                  UNLK      A6                
                                  RTS  
**************************** FIN PRINT *****************************************                             

**************************** SCAN **********************************************
* lee caracteres recibidos y los copia a otro bufer dado
SCAN:   
* Registros a salvar: A0-A5, D1-D3 (6+3 = 9 Registros de 4 bytes cada 1)  
                                  LINK      A6,#-36 
                                  MOVE.L    D1,-4(A6)
                                  MOVE.L    D2,-8(A6)
                                  MOVE.L    D3,-12(A6)
                                  MOVE.L    A0,-16(A6)
                                  MOVE.L    A1,-20(A6)
                                  MOVE.L    A2,-24(A6)
                                  MOVE.L    A3,-28(A6)
                                  MOVE.L    A4,-32(A6)
                                  MOVE.L    A5,-36(A6)   

* Poner D0 y D1 a 0 para recibir palabra y 0xFFFFFFFF en D3
                                  MOVE.L    #0,D1                       
                                  MOVE.L    #0,D0
                                  MOVE.L    #$FFFFFFFF,D3


* Lectura de parametros: (A6) m pila, 4(A6) dir ret, 8(A6) primer parametro
                                  MOVE.L    8(A6),A5            * Direccion del bufer (A5)
                                  MOVE.W    12(A6),D0           * Descriptor
                                  MOVE.W    14(A6),D2           * Tamaño

* Comprobacion del tamaño
                                  MOVE.W    #0,D1
                                  CMP.W     D2,D1
                                  BGE       SCERO               * si es 0 o inferior, salir

* Comprobacion del descriptor
                                  MOVE.W    #0,D1                         
                                  CMP.W     D0,D1
* Descriptor 0: Linea A
                                  BEQ       SCANA
                                  MOVE.W    #1,D1
                                  CMP.W     D0,D1
* Descriptor 1: Linea B
                                  BEQ       SCANB
* Si descriptor no es 0 o 1 error
                                  JMP       SCERR                         

* Caso de lectura por linea A

SCANA:   
                                  MOVE.W    #0,D1               * D1: Contador elementos leidos
SCABUC:  
                                  MOVE.W    #0,D0               * seleccionar bufer 0 BRA
                                  BSR       LEECAR              * llamada a leecar

                                  MOVE.L    #$FFFFFFFF,D3       * restaurar D3
                                  CMP.L     D0,D3               * si d0=(FFFFFFFF) -> buf circular vacio
                                  BEQ       SCFIN               * salir si buf circular vacio

                                  MOVE.B    D0,(A5)+            * mover a bufer incrementando ptr
                                  ADD.L     #1,D1               * incr. contador de leidos
                                  MOVE.L    D2,D3               * D3 = Tamano
                                  CMP.L     D1,D3               * comprobar si num leidos = tam
                                  BEQ       SCFIN               * si es igual, salir
                                  JMP       SCABUC              * si no volver a leer

* Caso de lectura por linea B

SCANB:   
                                  MOVE.W    #0,D1               * D1: Contador elementos leidos
SCBBUC: 
                                  MOVE.W    #1,D0               * seleccionar bufer 1 BRB
                                  BSR       LEECAR              * llamada a leecar

                                  MOVE.L    #$FFFFFFFF,D3       * restaurar D3
                                  CMP.L     D0,D3               * si d0=(FFFFFFFF) -> buf circular vacio
                                  BEQ       SCFIN               * salir si buf circular vacio

        
                                  MOVE.B    D0,(A5)+            * mover a bufer incrementando ptr
                                  ADD.L     #1,D1               * incr. contador de leidos
                                  MOVE.L    D2,D3               * D3 = Tamano
                                  CMP.L     D1,D3               * comprobar si num leidos = tam
                                  BEQ       SCFIN               * si es igual, salir
                                  JMP       SCBBUC              * si no volver a leer

* Casos especiales (error descriptor y tamaño no positivo)

SCERR:  
                                  MOVE.L    D3,D1               * Resultado/contador -1 (error)
                                  JMP       SCFIN

SCERO:   
                                  MOVE.L    #0,D1               * Resultado/contador  0

* Finalizar y salvar registros

SCFIN:  
                                  MOVE.L    D1,D0               * Pasar contador a resultado
                                  MOVE.L    -4(A6),D1     		
                                  MOVE.L    -8(A6),D2
                                  MOVE.L    -12(A6),D3
                                  MOVE.L    -16(A6),A0
                                  MOVE.L    -20(A6),A1
                                  MOVE.L    -24(A6),A2
                                  MOVE.L    -28(A6),A3
                                  MOVE.L    -32(A6),A4
                                  MOVE.L    -36(A6),A5
                                  UNLK      A6                
                                  RTS  

**************************** FIN SCAN ******************************************

**************************** RTI ***********************************************
* Registros a salvar: A0-A4, D0-D2 (5+3 = 8 Registros de 4 bytes cada 1)
RTI:   
                                  LINK      A6,#-32 ** Marco de pila
                                  MOVE.L    D0,-4(A6)
                                  MOVE.L    D1,-8(A6)
                                  MOVE.L    D2,-12(A6)
                                  MOVE.L    A0,-16(A6)
                                  MOVE.L    A1,-20(A6)
                                  MOVE.L    A2,-24(A6)
                                  MOVE.L    A3,-28(A6)
                                  MOVE.L    A4,-32(A6)

* Lectura del IMR (copia) y del ISR
                                  MOVE.B    IMRDUP,D0
                                  MOVE.B    ISR,D1
        
* Comprobar interrupciones simultaneamente pedidas y habilitadas
                                  AND.B     D1,D0

* Rx por linea A -> Bit 1
* Rx por linea B -> Bit 5
* Tx por linea A -> Bit 0
* Tx por linea B -> Bit 4

                                  BTST      #1,D0
                                  BNE       RTIRXA              * si no es cero (equals) saltar a caso RX linea a
                                  BTST      #5,D0
                                  BNE       RTIRXB              * Rx linea b
                                  BTST      #0,D0
                                  BNE       RTITXA              * Tx linea a
                                  BTST      #4,D0
                                  BNE       RTITXB              * Tx linea b
                                  JMP       RTIRST              * si se llega sin que se de un caso de los 4, salir

* Caso Rx por linea A

RTIRXA: 
                                  MOVE.L    #0,D0               * selecciona bufer circular 0 (BIRA)
                                  MOVE.L    #0,D1               * resetea D1 a 0 para que pueda contener byte

                                  MOVE.B    RBA,D1              * coloca byte de RBA en D1 para ser escrito
                                  BSR       ESCCAR              * escribe caracter en el buf interno (si se puede)
* Si ESCCAR devuelve error no es necesario hacer nada (se tira el byte)
                                  JMP       RTIRST 

* Caso Rx por linea B

RTIRXB: 
                                  MOVE.L    #1,D0               * selecciona bufer circular 1 (BIRB)
                                  MOVE.L    #0,D1               * resetea D1 a 0 para que pueda contener byte

                                  MOVE.B    RBB,D1              * coloca byte de RBB en D1 para ser escrito
                                  BSR       ESCCAR              * escribe caracter en el buf interno (si se puede)
* Si ESCCAR devuelve error no es necesario hacer nada (se tira el byte)
                                  JMP       RTIRST 

* Caso Tx por linea A

RTITXA: 
                                  MOVE.L    #2,D0               * selecciona bufer circular 2 (BITA) 
                                  BSR       LEECAR              * lee del bufer circular

                                  MOVE.L    #$FFFFFFFF,D1
                                  CMP       D0,D1               * si d0=-1 (FFFFFFFF) -> buf circular vacio
                                  BEQ       TXADIS              * tratamiento buf interno vacio = desactivar ints A

                                  MOVE.B    D0,TBA              * transmite el caracter leido si existe
                                  JMP       RTIRST              * a la salida de RTI


TXADIS:
                                  MOVE.B    IMRDUP,D0           * contenido imr en d0
                                  AND.B     #%11111110,D0       * pone bit 0 a 0 desactivando int Tx A
                                  MOVE.B    D0,IMR              * actualiza el imr
                                  MOVE.B    D0,IMRDUP           * actualiza su duplicado
                                  JMP       RTIRST              * salida de RTI

* Caso Tx por linea B

RTITXB: 
                                  MOVE.L    #3,D0               * selecciona bufer circular 3 (BITB) 
                                  BSR       LEECAR              * lee del bufer circular

                                  MOVE.L    #$FFFFFFFF,D1
                                  CMP       D0,D1               * si d0=-1 (FFFFFFFF) -> buf circular vacio
                                  BEQ       TXBDIS              * tratamiento buf interno vacio = desactivar ints B

                                  MOVE.B    D0,TBB              * transmite el caracter leido si existe
                                  JMP       RTIRST              * a la salida de RTI

TXBDIS:
                                  MOVE.B    IMRDUP,D0           * contenido imr en d0
                                  AND.B     #%11101111,D0       * pone bit 4 a 0 desactivando int Tx B
                                  MOVE.B    D0,IMR              * actualiza el imr
                                  MOVE.B    D0,IMRDUP           * actualiza su duplicado

* Restaurar registros de pila y salir
RTIRST: 
                                  MOVE.L    -4(A6),D0     		
                                  MOVE.L    -8(A6),D1
                                  MOVE.L    -12(A6),D2
                                  MOVE.L    -16(A6),A0
                                  MOVE.L    -20(A6),A1
                                  MOVE.L    -24(A6),A2
                                  MOVE.L    -28(A6),A3
                                  MOVE.L    -32(A6),A4
                                  UNLK      A6                
                                  RTE                                 

**************************** FIN RTI *******************************************



**************************** PROGRAMA PRINCIPAL ********************************
* Tester para casos limite de las subrutinas. Instala manejadores de excepcion
INICIO: 
                                  MOVE.L    #BUS_ERROR,8 	    * Error de bus
                                  MOVE.L    #ADDRESS_ER,12 	    * Error de direccion
                                  MOVE.L    #ILLEGAL_IN,16 	    * Instruccion ilegal
                                  MOVE.L    #PRIV_VIOLT,32 	    * Violacion de privilegio
                                  MOVE.L    #ILLEGAL_IN,40 	    * Instruccion ilegal
                                  MOVE.L    #ILLEGAL_IN,44 	    * Instruccion ilegal
                                  BSR       INIT
                                  MOVE.W    #$2000,SR 
                                  MOVE.L    #TAMBUF,D5

* ESCCAR: Bufer Lleno
FILLBUF:
                                  MOVE.L    #0,D1
                                  MOVE.B    #$F1,D1
                                  MOVE.L    #3,D0
                                  MOVE.L    #BITB,A5
                                  BSR       ESCCAR
                                  SUB.L     #1,D5
                                  MOVE.L    #0,D3
                                  CMP.L     D5,D3
                                  BNE       FILLBUF
                                  NOP                           * result. de ultima op debe ser FFFFF (debido a burbuja)
                                  MOVE.L    #TAMBUF,D5
* LEECAR: Bufer vacio
EMPTBUF:                
                                  MOVE.L    #3,D0
                                  MOVE.L    #BITB,A5
                                  BSR       LEECAR
                                  SUB.L     #1,D5
                                  MOVE.L    #0,D3
                                  CMP.L     D5,D3
                                  BNE       EMPTBUF
                                  NOP                           * result. de ultima op debe ser FFFFF (debido a que hay tambuf-1)

* Scan: Descriptor erroneo
SCWRONGD:                        
                                  MOVE.W    #2,-(A7) 		
                                  MOVE.W    #5,-(A7) 		    * Descriptor erroneo
                                  MOVE.L    #4,-(A7) 	
                                  BSR       SCAN
                                  NOP                           * Comprobar resultado en D0
* Print: Descriptor erroneo
PRWRONGD:                        
                                  BSR       PRINT
                                  NOP                           * Comprobar resultado en D0
                                  ADD.L     #8,A7               * Restaura pila
* Scan: Tamano Cero
SCSZERO:                        
                                  MOVE.W    #0,-(A7) 		
                                  MOVE.W    #0,-(A7) 		    * Descriptor erroneo
                                  MOVE.L    #4,-(A7) 	
                                  BSR       SCAN
                                  NOP                           * Comprobar resultado en D0
* Print: Tamano Cero
PRSZERO:                        
                                  BSR       PRINT
                                  NOP                           * Comprobar resultado en D0
                                  ADD.L     #8,A7               * Restaura pila
                                  BREAK

BUS_ERROR:  
                                  BREAK 						
                                  NOP
ADDRESS_ER: 
                                  BREAK 						
                                  NOP
ILLEGAL_IN: 
                                  BREAK 						
                                  NOP
PRIV_VIOLT: 
                                  BREAK      
                                  NOP
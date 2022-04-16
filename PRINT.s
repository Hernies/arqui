PRINT:
    LINK    A6,#0
    CLR     D2                            *Limpieza D2( para guardar el descriptor)
    CLR     D3                            *Limpieza D3( para guardar el Tamaño)
    CLR     D4
    CLR     D5                            *Contador a 0
    CLR     D6
    MOVE.W  12(A6),D2                        *Descriptor a D2
    CMP.W   #0,D2                             *Descriptor ==0?
    BEQ     PA                              *Estoy en A
    CMP.W   #1,D2                             *Descriptor ==1 ?
    BEQ     PB                              *Estoy en B
                                            *El descriptor pasado como parametro está mal
	MOVE.L  #$ffffffff,D0                    *Se mete un -1 en D0
    UNLK    A6                             
    RTS
PA:
    MOVE.L  #2,D4                            *Se mete un 2 en D4 porque es el que accede al buffer de Trasmision de A
    BRA     PRNT
PB:
    MOVE.L  #3,D4                            *Se mete un 3 en D4 porque es el que accede al buffer de Trasmision de B
    
PRNT:
    MOVE.W  14(A6),D3                        *Guarda el tamanio en D3
    MOVE.L  8(A6),A1                         *Mete el Buffer pasado commo parametro en el registro A1
BC_PRNT:   
    CMP.L   D5,D3                             *Si contador==tamanio hemos terminado
    BEQ     PRFIN
    MOVE.B  (A1)+,D1					        *Sacamos dato y avanzamos buffer
    MOVE.L  D4,D0                            *Se mete en D0 el identificador del buffer
    BSR     ESCCAR
    CMP     #$ffffffff,D0                       *Si la llamada a ESSCAR ha devuelto un -1(buffer lleno) se termina
    BEQ     PRFIN
    ADD.L   #1,D5                             *Avanzar contador
    CMP.B   #13,D1                            *Comprueba si se ha escrito un retorno de carro
    BNE     BC_PRNT                            *Si no, salta al bucle
    MOVE.B  #1,flagPRT                       *Si he escrito un 0xD activo el flag
    BRA     BC_PRNT

PRFIN:
    CMP.B #0,flagPRT                        *Comprueblo si el flag está activado
    BEQ PRNT_FIN                            
    MOVE.L #0,D6                            *limpieza de D6
    MOVE.W SR,D6                    *Guardar SR para restituirlo despues 
    MOVE.W   #$2700,SR              *Inhibe interrupciones
    CMP #2,D4                       *Compruebo en que buffer estoy para saber que bit del IMR activar
    BEQ PRNT_ACA                    *Salto para activatr el bit de A de IMR
    BSET #4,COPIA_IMR               *Activo el BIT 4
    BRA PRNT_IMR
NXT_P:
    BSET    #0,COPIA_IMR
PRNT_IMR:
    MOVE.B  COPIA_IMR,IMR
    MOVE.W  D6,SR                    *Restituimos el SR al valor que tenia previamente 
    MOVE.B  #0,flagPRT               *reset a 0 del flag
PRNT_FIN:
    MOVE.L  D5,D0                    *Contador a D0
    UNLK    A6
    RTS
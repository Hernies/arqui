*inicializar SP y PC
**************************
        ORG $0
        DC.L $8000
        DC.L INICIO

        ORG $400

**************************
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
                    MOVEM.L	A0-A5/D1-D5,-(A6)
                    ** RESET DE PARAMETROS Y LECTURA DE PARAMETROS(BUFFER(ireccion) 8,DESCRIPTOR(Dato) 12,TAMAÑO(dato) 16)**
                    CLR         D0              * RETURN (0XFFFFFFFF O NUMERO DE CARACTERES ACEPTADOS PARA ESCRITURA)
                    CLR         D1
                    CLR         D2
                    CLR         D4
                    MOVE.L     8(A6),A1        * DIR BUFFER A A1
                    MOVE.L     12(A6),D1       * DESCRIPTOR A D1
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
                    MOVE.L      D2,D3           * COPIO EL TAMAÑO EN D3
    PA:             CMP.L       #0,D3           * SI SE HA ESCRITO TODO -> FIN
                    BEQ         FINP
                    MOVE        D0,D4
                    MOVE        (A1)+,D1        * COPIAMOS EN D1 EL BUFFER
                    MOVE.L      #2,D0           * ESCCAR ESRIBA POR LTA
                    BSR         ESCCAR 
                    CMP.L       #$FFFFFFFF,D0   * MIRAMOS SI ESCCAR HA FALLADO SI?-> FIN
                    MOVE.L      D4,D0
                    BEQ         FINP     
                    SUB.L       #1,D3
                    ADD.L       #1,D0
                    BR          PA
           
                    MOVE.L      D2,D3           * COPIO EL TAMAÑO EN D3
    PB:             CMP.L       #0,D3           * SI SE HA ESCRITO TODO -> FIN
                    BEQ         FINP
                    MOVE        D0,D4
                    MOVE        (A1)+,D1        * 
                    MOVE.L      #3,D0           * ESCCAR ESRIBA POR LTB
                    BSR         ESCCAR 
                    CMP.L       #$FFFFFFFF,D0   
                    BEQ         FINP
                    MOVE.L      D4,D0     
                    SUB.L       #1,D3
                    ADD.L       #1,D5
                    BR          PB

    FINP:           CLR         D1  
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



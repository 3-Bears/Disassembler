*-----------------------------------------------------------
* Title       : Testing
* Written by  : Terence Calhoun, Joseph Schooley, Nguyen Tong
* Date        : 11/5/2013
* Description : Test code for Dissambler
* Instructions: MOVE, MOVEA, MOVEM, ADD, ADDA, ADDQ
*               SUB, SUBA, SUBI, MULU, DIVS, LEA
*               AND, ORI, EOR, EORI, NOT, ASL, LSR
*               BTST, CMP, CMPA, CMPI
*               Bcc(BEQ, BLT, BNE, BHI)
*               JSR, RTS
* EA Modes:     Data Register Direct
*               Address Register Indirect
*               Immediate Data
*               Address Reg indirect w/ post incrementing
*               Address Reg indirect w/ pre decrementing
*               Absolute Long Address
*               Absolute Word Address
*-----------------------------------------------------------

*Max Unsigned Values in Hex for Byte, Word, Long
VHEX1   EQU $FA
VHEX2   EQU $DADA
VHEX3   EQU $ADADDADA
VHEX4   EQU $45
CBITS   EQU $00000000

    ORG    $7000
START:                  ; first instruction of program
******************************************************
*   8        8  8888888 8           8  888888888
*   8 8    8 8  8     8  8         8   8
*   8  8  8  8  8     8   8       8    8
*   8   88   8  8     8    8     8     888888888
*   8        8  8     8     8   8      8
*   8        8  8     8      8 8       8 
*   8        8  8888888       8        888888888
******************************************************


*****************************************************
*    Source: <EA> = Dn
*    Destination: Dn
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 
    MOVE.L  #VHEX3, D0
    MOVE.B  D0, D1
    MOVE.W  D0, D1
    MOVE.L  D0, D1
    MOVE.L  #CBITS, D0
    MOVE.L  #CBITS, D1      

*****************************************************
*    Source: <EA> = An
*    Destination: Dn
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 
    MOVE.L  #VHEX3, $7000
    MOVEA.L #$7000, A2
    MOVE.W  A2, D0
    MOVE.L  A2, D0
    MOVE.L  #CBITS, D0
    
*****************************************************
*    Source: <EA> = (An)
*    Destination: Dn
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVE.B  (A2), D0
    MOVE.W  (A2), D0
    MOVE.L  (A2), D0
    MOVE.L  #CBITS, D0
    MOVEA.L #CBITS, A2

*****************************************************
*    Source: <EA> = (An)+
*    Destination: Dn
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVE.B  (A2)+, D0
    MOVEA.L #CBITS, A2
    MOVEA.L #$7000, A2
    MOVE.W  (A2)+, D0
    MOVEA.L #CBITS, A2
    MOVEA.L #$7000, A2
    MOVE.L  (A2)+, D0
    MOVE.L  #CBITS, D0
    MOVEA.L #CBITS, A2    
    
*****************************************************
*    Source: <EA> = -(An)
*    Destination: Dn
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVEA.L #$7004, A2
    MOVE.B  -(A2), D0
    MOVEA.L #CBITS, A2
    MOVEA.L #$7004, A2
    MOVE.W  -(A2), D0
    MOVEA.L #CBITS, A2
    MOVEA.L #$7004, A2
    MOVE.L  -(A2), D0
    MOVE.L  #CBITS, D0
    MOVEA.L #CBITS, A2  
    
*****************************************************
*    Source: <EA> = (xxx).W
*    Destination: Dn
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVE.B  $7000, D0
    MOVE.W  $7000, D0
    MOVE.L  $7000, D0 
    MOVE.L  #CBITS, D0  
*****************************************************
*    Source: <EA> = (xxx).L
*    Destination: Dn
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

*    MOVE.B  $00007000, D0
*    MOVE.W  $00007000, D0
*    MOVE.L  $00007000, D0  

*****************************************************
*    Source: <EA> = #<data>
*    Destination: Dn
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVE.B  #VHEX1, D0
    MOVE.W  #VHEX2, D0
    MOVE.L  #VHEX3, D0
    MOVE.L  #CBITS, D0   
    
*****************************************************
*   Source: <EA> = Dn
*   Destination:(An)
*   Valid Test Section for MOVE instruction 
*   into Data Register
*****************************************************     
    MOVE.L  $7000, D0 
    MOVEA.L #$7004, A3
    MOVE.B  D0, (A3)
    MOVE.W  D0, (A3)
    MOVE.L  D0, (A3)
    MOVE.L  #CBITS, D0  
    MOVE.L  #CBITS, (A3)

*****************************************************
*   Source: <EA> = An
*   Destination:(An)
*   Valid Test Section for MOVE instruction 
*   into Data Register
*****************************************************     
    MOVEA.L $7000, A2 
    MOVE.W  A2, (A3)
    MOVE.L  A2, (A3)  
    MOVE.L  #CBITS, (A3)

*****************************************************
*   Source: <EA> = (An)
*   Destination:(An)
*   Valid Test Section for MOVE instruction 
*   into Data Register
*****************************************************     
    MOVEA.L #CBITS,A2
    MOVEA.L #$7000, A2
    MOVE.W  (A2), (A3)
    MOVE.L  (A2), (A3)  
    MOVE.L  #CBITS, (A3)

*****************************************************
*   Source: <EA> = (An)+
*   Destination:(An)
*   Valid Test Section for MOVE instruction 
*   into Data Register
*****************************************************     
    MOVEA.L #CBITS,A2
    MOVEA.L #$7000, A2
    MOVE.B  (A2)+, (A3)
    MOVEA.L #CBITS,A2
    MOVEA.L #$7000, A2
    MOVE.W  (A2)+, (A3)
    MOVEA.L #CBITS,A2
    MOVEA.L #$7000, A2
    MOVE.L  (A2)+, (A3)
    MOVEA.L #CBITS,A2
    MOVEA.L #$7003, A2  
    MOVE.L  #CBITS, (A3)
*****************************************************
*   Source: <EA> = -(An)
*   Destination:(An)
*   Valid Test Section for MOVE instruction 
*   into Data Register
*****************************************************     
    MOVE.B  -(A2), (A3)
    MOVE.W  -(A2), (A3)
    MOVEA.L #CBITS,A2
*    MOVE.L  -(A2), (A3)
    MOVEA.L #CBITS, A2
    MOVE.L  #CBITS, (A3)    

*****************************************************
*   Source: <EA> = (xxx).W
*   Destination:(An)
*   Valid Test Section for MOVE instruction 
*   into Data Register
*****************************************************     
    MOVE.B  $7000, (A3)
    MOVE.W  $7000, (A3)
    MOVE.L  $7000, (A3)
    MOVE.L  #CBITS, (A3)  

*****************************************************
*   Source: <EA> = (xxx).L
*   Destination:(An)
*   Valid Test Section for MOVE instruction 
*   into Data Register
*****************************************************     
*    MOVE.B  $7000, (A3)
*    MOVE.W  $7000, (A3)
*    MOVE.L  $7000, (A3)
*    MOVE.L  #CBITS, (A3)  
*****************************************************
*   Source: <EA> = #<data>
*   Destination:(An)
*   Valid Test Section for MOVE instruction 
*   into Data Register
*****************************************************     
    MOVEA.L #$7000, A3

*   MOVE to (An) Max Bountry Hex w/ labels
    MOVE.B  #VHEX1, (A3)
    MOVE.W  #VHEX2, (A3)
    MOVE.L  #VHEX3, (A3)
    MOVE.L  #CBITS, (A3)

*****************************************************
*    Source: <EA> = Dn
*    Destination: (An)+
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVE.L  #VHEX3, D0
    MOVEA.L #$7004, A2
    MOVE.B  D0,(A2)+
    MOVEA.L #CBITS, A2
    MOVEA.L #$7004, A2
    MOVE.W  D0,(A2)+
    MOVEA.L #CBITS, A2
    MOVEA.L #$7004, A2
    MOVE.L  D0,(A2)+
    MOVE.L  #CBITS, D0
    MOVEA.L #CBITS, A2    

*****************************************************
*    Source: <EA> = (An)
*    Destination: (An)+
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVE.L  #CBITS, $7000
    MOVEA.L  #$7000, A3
    MOVEA.L #$7004, A2
    MOVE.B  (A3),(A2)+
    MOVEA.L #CBITS, A2
    MOVEA.L #$7004, A2
    MOVE.W  (A3),(A2)+
    MOVEA.L #CBITS, A2
    MOVEA.L #$7004, A2
    MOVE.L  (A3),(A2)+
    MOVE.L  #CBITS, D0
    MOVEA.L #CBITS, A2 

*****************************************************
*    Source: <EA> = -(An)
*    Destination: (An)+
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    
    MOVEA.L #$7008, A3
    MOVEA.L #$6000, A2
    MOVE.W  -(A3),(A2)+
    MOVEA.L #CBITS, A2
    MOVEA.L #CBITS, A3
    MOVEA.L #$7008, A3
    MOVEA.L #$6000, A2
    MOVE.L  -(A3),(A2)+
    MOVEA.L #CBITS, A3
    MOVEA.L #CBITS, A2

*****************************************************
*    Source: <EA> = (xxx).W
*    Destination: (An)+
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    
    MOVEA.L #$7000, A2
    MOVE.L  #VHEX3, $7000
    MOVE.W  $6000,(A2)+
    MOVEA.L #$7000, A2
    MOVE.L  $6000,(A2)+
    MOVEA.L #CBITS, A2

*****************************************************
*    Source: <EA> = (xxx).L
*    Destination: (An)+
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 
*    MOVEA.L #$7000, A2
*    MOVE.L  #VHEX3, $7000
*    MOVE.W  $6000,(A2)+
*    MOVEA.L #$7000, A2
*    MOVE.L  $6000,(A2)+
*    MOVEA.L #CBITS, A2

*****************************************************
*    Source: <EA> = #<data>
*    Destination:(An)+
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 


    MOVEA.L #$7004, A2
    MOVE.L  #VHEX3,(A2)+
    MOVE.L  #CBITS, D0
    MOVEA.L #CBITS, A2    
    
*****************************************************
*    Source: <EA> = Dn
*    Destination: -(An)
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVE.L  #VHEX3, D0
    MOVEA.L #$7004, A2
    MOVE.B  D0,-(A2)
    MOVEA.L #CBITS, A2
    MOVEA.L #$7004, A2
    MOVE.W  D0,-(A2)
    MOVEA.L #CBITS, A2
    MOVEA.L #$7004, A2
    MOVE.L  D0,-(A2)
    MOVE.L  #CBITS, D0
    MOVEA.L #CBITS, A2    

*****************************************************
*    Source: <EA> = (An)
*    Destination: (An)+
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVE.L  #CBITS, $7000
    MOVEA.L  #$7000, A3
    MOVEA.L #$7004, A2
    MOVE.B  (A3),-(A2)
    MOVEA.L #CBITS, A2
    MOVEA.L #$7004, A2
    MOVE.W  (A3),-(A2)
    MOVEA.L #CBITS, A2
    MOVEA.L #$7004, A2
    MOVE.L  (A3),-(A2)
    MOVE.L  #CBITS, D0
    MOVEA.L #CBITS, A2 

*****************************************************
*    Source: <EA> = -(An)
*    Destination: (An)+
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    
    MOVEA.L #$7008, A3
    MOVEA.L #$6008, A2
    MOVE.W  -(A3),-(A2)
    MOVEA.L #CBITS, A2
    MOVEA.L #CBITS, A3
    MOVEA.L #$7008, A3
    MOVEA.L #$6000, A2
    MOVE.L  -(A3),-(A2)
    MOVEA.L #CBITS, A3
    MOVEA.L #CBITS, A2

*****************************************************
*    Source: <EA> = (xxx).W
*    Destination: (An)+
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    
    MOVEA.L #$7004, A2
    MOVE.L  #VHEX3, $7004
    MOVE.W  $6000,-(A2)
    MOVEA.L #$7000, A2
    MOVE.L  $6000,-(A2)
    MOVEA.L #CBITS, A2

*****************************************************
*    Source: <EA> = (xxx).L
*    Destination: (An)+
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 
*    MOVEA.L #$7000, A2
*    MOVE.L  #VHEX3, $7000
*    MOVE.W  $6000,(A2)+
*    MOVEA.L #$7000, A2
*    MOVE.L  $6000,(A2)+
*    MOVEA.L #CBITS, A2

*****************************************************
*    Source: <EA> = #<data>
*    Destination:(An)+
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 


    MOVEA.L #$7004, A2
    MOVE.L  #VHEX3,-(A2)
    MOVE.L  #CBITS, D0
    MOVEA.L #CBITS, A2    


*****************************************************
*    Source: <EA> = Dn
*    Destination: (xxx).W
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 
    MOVE.L  #VHEX3, D0
    MOVE.B  D0, $7008
    MOVE.W  D0, $7008
    MOVE.L  D0, $7008
    MOVE.L  #CBITS, $7008      

*****************************************************
*    Source: <EA> = An
*    Destination: (xxx).W
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 
    MOVE.L  D0, A2
    MOVE.W  A2, $7008  
    MOVE.L  A2, $7008  
    MOVE.L  #CBITS, $7008  
    
*****************************************************
*    Source: <EA> = (An)
*    Destination: (xxx).W
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVE.B  (A2),$7008  
    MOVE.W  (A2),$7008  
    MOVE.L  (A2),$7008    

*****************************************************
*    Source: <EA> = (An)+
*    Destination: (xxx).W
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVEA.L #$7008, A2
    MOVE.W  (A2)+, $6000 
    MOVEA.L #CBITS, A2
    MOVEA.L #$7008, A2
    MOVE.L  (A2)+, $6000
    MOVE.L  #CBITS, A2
    MOVE.L  #CBITS, $6000 
    
*****************************************************
*    Source: <EA> = -(An)
*    Destination:  (xxx).W
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVEA.L #$7008, A2
    MOVE.B  -(A2), $6000
    MOVEA.L #CBITS, A2
    MOVEA.L #$7008, A2
    MOVE.W  -(A2), $6000
    MOVEA.L #CBITS, A2
    MOVEA.L #$7008, A2
    MOVE.L  -(A2), $6000
    MOVE.L  #CBITS, $6000
    MOVEA.L #CBITS, A2  
    
*****************************************************
*    Source: <EA> = (xxx).W
*    Destination: (xxx).W
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVE.B  $7008, $7000
    MOVE.W  $7008, $7000
    MOVE.L  $7008, $7000
    MOVE.L  #CBITS, $7000
*****************************************************
*    Source: <EA> = (xxx).L
*    Destination: (www).W
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

*    MOVE.B  $00007000, $7000
*    MOVE.W  $00007000, $7000
*    MOVE.L  $00007000, $7000  

*****************************************************
*    Source: <EA> = #<data>
*    Destination: (www).W
*    Valid Test Section for MOVE instruction 
*    into Data Register
***************************************************** 

    MOVE.B  #VHEX1, $7000
    MOVE.W  #VHEX2, $7000
    MOVE.L  #VHEX3, $7000
    MOVE.L  #CBITS, $7000   
     
    SIMHALT             ; halt simulator
    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

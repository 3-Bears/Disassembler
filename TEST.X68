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
* Legal Instructions:
*               Op-Codes that are implemented in the 
*               disassembler. This will print out normally
* Illegal Instructions:
*               Op-Codes that are not implemented, branch
*               to DATA
*-----------------------------------------------------------
    ORG    $7000

VHEX1   EQU $FA
VHEX2   EQU $DADA
VHEX3   EQU $ADADDADA
VHEX4   EQU $45
CBITS   EQU $00000000
VBIN1   EQU %11111111110011111100111111001111


*-----------------------MOVE--------------------------------
* Syntax: <ea>, <ea>
* Size: B, W, L
*-----------------------------------------------------------

*LEGAL INSTRUCTIONS

    MOVE.B  (6*2,A6,D2),(A4)     (d8,An,Xn),(An)
    MOVE.W  (79,A6,A1),A5        (d8,An,Xn),An
    MOVE.L  (5,A0,D2.L),D6       (d8,An,Xn.SIZE),Dn
    

    MOVE.B  VHEX1, D0           <ea>,Dn
    MOVE.W  VHEX2, D1
    MOVE.L  #VHEX3, D2
    
    MOVE.B  VHEX1, (A0)         <ea>,(An)
    MOVE.W  #VHEX2, (A1)
    MOVE.L  VHEX3, (A2)
    
    MOVE.B  #VHEX1, (A3)+       <ea>,(An)+
    MOVE.W  VHEX2, (A4)+
    MOVE.L  VHEX3, (A5)+
    
    MOVE.B  VHEX1, -(A0)        <ea>,-(An)
    MOVE.W  VHEX2, -(A2)
    MOVE.L  #VHEX3, -(A4)
            
    MOVE.B  VHEX1, VHEX2        <ea>,(xxx).W
    MOVE.W  VHEX2, VHEX3        <ea>,(xxx).L
    MOVE.L  CBITS, $00F00200    <ea>,#<data>
    
    MOVE.B  D0, VHEX2           Dn,<ea>
    MOVE.W  D1, $00F00210
    MOVE.L  D2, (A1)+
    
    MOVE.B  (A1),$FF00          (An),<ea>
    MOVE.W  (A3),D3
    MOVE.L  (A5),-(A1)
    
    MOVE.L  A0, (A2)            An,<ea>
    MOVE.W  A1, (A3)+
    MOVE.L  A2, VHEX3
    
    MOVE.B  -(A0),VHEX2         -(An),<ea>
    MOVE.W  -(A1),D1
    MOVE.L  -(A2),(A2)+
    
    MOVE.W  VHEX2, D1           (xxx).W, <ea>
    MOVE.L  VHEX3, VHEX2        (xxx).L, <ea>
    MOVE.L  #%0001001111001111, VHEX3   #<data>,<ea>
    
*ILLEGAL INSTRUCTIONS

    MOVE.B  VHEX1, -(SP)        <ea>, -(SP)
    MOVE.W  (VHEX1,A1),(A2)     (d16,An),<ea>
    MOVE.W  (VHEX2,PC),-(A1)    (d16,PC),<ea>
    MOVE.L  (SP)+, D3           (SP)+, <ea>
    MOVEQ.L #VHEX1,D0           MOVEQ
    
*-----------------------MOVEA--------------------------------
* Syntax: <ea>, An
* Size:   W, L
*-----------------------------------------------------------

*LEGAL INSTRUCTIONS

    MOVEA.W  D0,A0              Dn,An
    MOVEA.L  A0,A1              An,An
    MOVEA.L  (A1),A2            (An),An
    
    MOVEA.L  (A2)+,A3           (An)+,An
    MOVEA.W  -(A3),A4           -(An),An
    MOVEA.W  VHEX2,A5            (xxx).W,An
    
    MOVEA.L   VHEX3,A0           (xxx).L,An
    MOVEA.L  #VHEX2,A1           #<data>,An
    MOVEA.L   VBIN1,A6            (xxx).L,An

*ILLEGAL INSTRUCTIONS        
    MOVEA.W  (VHEX1,A5),A6        (d16,An),An
    MOVEA.W  (VHEX2,PC),A7        (d16,PC),An
    MOVEQ.L   #VHEX1, D0           MOVEQ
    MOVEQ.L   #VHEX1, D1           MOVEQ
    
*-----------------------MOVEM--------------------------------
* Syntax: <list>,<ea>   -   <ea>,<list>
* Size:   W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS

*Register to Memory - <list>,<ea>
    MOVEM.W     D1-D3/A1, (A0)      <list>,(An)
    MOVEM.W     D1/A0-A1, VHEX2     <list>,(xxx).W
    MOVEM.L     D0-D4/A0-A4, -(A1)  <list>,-(An)
    MOVEM.L     D2-D4/A4, VHEX3     <list>,(xxx).L
    
*Memory to Register - <ea>,<list>
    MOVEM.W     (A1),D1-D3/A1       (An),<list>
    MOVEM.W     VHEX2, D1/A0-A1     (xxx).W,<list>
    MOVEM.L     (A2)+, D0-D4/A0-A4  (An)+,<list>
    MOVEM.L     VHEX3, D2-D4/A4     (xxx).L,<list>
    
*ILLEGAL INSTRUCTIONS

    MOVEM.W     D1-D2/A0-A1, (VHEX1,A0) <list>,(d16,An)
    MOVEM.L     D1-D2/A0-A1, (VHEX1,A1) <list>,(d16,An)
    MOVEM.W     (VHEX1,A2),D1-D2/A0-A1  (d16,An),<list>
    MOVEM.L     (VHEX2,PC),D1-D2/A0-A1  (d16,PC),<list>
    
*-----------------------ADD----------------------------------
* Syntax: <ea>,Dn   -   Dn,<ea>
* Size:   B, W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
*<ea>,Dn
    ADD.B       D0,D1       Dn,Dn
    ADD.W       D1,D2
    ADD.L       D2,D3
    
    ADD.W       A1,D1       An,Dn
    ADD.L       A2,D2
    ADD.L       A3,D5
    
    ADD.B       (A0),D2     (An),Dn
    ADD.W       (A1),D3
    ADD.L       (A2),D4
    
    ADD.B       (A3)+,D0    (An)+,Dn
    ADD.W       (A4)+,D1
    ADD.L       (A5)+,D2
    
    ADD.B       -(A0),D3    -(An),Dn
    ADD.W       -(A1),D4    
    ADD.L       -(A2),D5
    
    ADD.B       VHEX2,D0    (xxx).W,Dn
    ADD.W       VHEX3,D1    (xxx).L,Dn
    ADD.L       #VHEX1,D3   #<data>,Dn
    
*Dn,<ea>

    ADD.W       D0,A1       Dn,An
    ADD.W       D1,A2
    ADD.L       D2,A3
    
    ADD.B       D3,(A4)     Dn,(An)
    ADD.W       D4,(A5) 
    ADD.L       D5,(A6)
    
    ADD.B       D0,(A0)+    Dn,(An)+
    ADD.W       D1,(A1)+
    ADD.L       D2,(A2)+
    
    ADD.B       D3,-(A3)    Dn,-(An)
    ADD.W       D4,-(A4)
    ADD.L       D5,-(A5)
    
    ADD.B       D1,VHEX2    Dn,(xxx).W
    ADD.L       D2,VHEX3    Dn,(xxx).L
    ADD.W       D3,VBIN1    Dn,(xxx).L
    
*ILLEGAL INSTRUCTIONS

    ADD.B       (VHEX1,A1),D0   (d16,An),Dn
    ADD.W       (VHEX2,PC),D1   (d16,PC),Dn
    ADD.L       D3,(VHEX1,A1)   Dn,(d16,An)

*-----------------------ADDA---------------------------------
* Syntax: <ea>,An   
* Size:   W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
    ADDA.W       D0,A0           Dn,An
    ADDA.L       D1,A1   
    
    ADDA.L       A2,A3           An,An
    ADDA.W       A3,A4
    
    ADDA.W       (A0),A0         (An),An
    ADDA.L       (A2),A2
    
    ADDA.L       (A1)+,A1        (An)+,An
    ADDA.W       (A2)+,A2
   
    ADDA.W       -(A3),A2        -(An),An
    ADDA.L       -(A2),A3
    
    ADDA.L       VHEX2,A0        (xxx).W,An
    ADDA.W       VHEX2,A2    
    
    ADDA.W       VHEX3,A3        (xxx).L,An
    ADDA.L       VHEX3,A4
    
    ADDA.L       #VBIN1,A5       #<data>,An

*ILLEGAL INSTRUCTIONS

    ADDA.W       (VHEX1,A2),A1   (d16,An),An
    ADDA.L       (VHEX2,PC),A3   (d16,PC),An
    ADDA.L       (VHEX1,A3),A3   (d16,An),An

*-----------------------ADDQ---------------------------------
* Syntax: #<data>,<ea>
* Size:   B, W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
    ADDQ.B      #$1,D1       #<data>,Dn
    ADDQ.W      #$2,D2
    ADDQ.L      #3,D3
    
    ADDQ.W      #$4,A0       #<data>,An
    ADDQ.L      #$5,A1
    ADDQ.L      #$6,A2
    
    ADDQ.B      #$7,(A0)     #<data>,(An)
    ADDQ.W      #$8,(A1)
    ADDQ.L      #1,(A2)
    
    ADDQ.B      #$2,(A2)+    #<data>,(An)+
    ADDQ.W      #$3,(A3)+
    ADDQ.L      #$4,(A4)+
    
    ADDQ.B      #$5,-(A5)    #<data>,-(An)
    ADDQ.W      #6,-(A6)
    ADDQ.L      #$7,-(A7)
    
    ADDQ.B      #1,VHEX2     #<data>,(xxx).W
    ADDQ.L      #2,VHEX3     #<data>,(xxx).L
    ADDQ.W      #$4,VBIN1    #<data>,(xxx).L
    
*ILLEGAL INSTRUCTIONS
    ADDQ.W      #8,(VHEX1,A2)   #<data>,(d16,An)
    ADDI.W      #VHEX1,D0       ADDI
    ADDX.L      D0,D1           ADDX
    
*-----------------------SUB----------------------------------
* Syntax: <ea>,Dn   -   Dn,<ea>
* Size:   B, W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
*<ea>,Dn

    SUB.B       D0,D1       Dn,Dn
    SUB.W       D2,D3
    
    SUB.L       A1,D0       An,Dn
    SUB.W       A4,D3
    
    SUB.B       (A3),D3     (An),Dn
    SUB.L       (A2),D0
    
    SUB.B       (A0)+,D1    (An)+,Dn
    SUB.W       (A3)+,D2
    
    SUB.L       -(A1),D2    -(An),Dn
    SUB.B       -(A2),D1    
    
    SUB.W       VHEX2,D0    (xxx).W,Dn
    SUB.L       VBIN1,D2    (xxx).L,Dn
    SUB.B       #$F0,D4     #<data>,Dn
    
*Dn,<ea>

    SUB.W       D0,A1       Dn,An
    SUB.L       D3,A4
    
    SUB.B       D3,(A3)     Dn,(An)
    SUB.W       D0,(A2)
    
    SUB.L       D1,(A0)+    Dn,(An)+
    SUB.B       D2,(A3)+
    
    SUB.W       D2,-(A1)    Dn,-(An)
    SUB.L       D1,-(A2)
    
    SUB.B       D0,VHEX2    Dn,(xxx).W
    SUB.W       D2,VBIN1    Dn,(xxx).L
    SUB.L       D3,VHEX3    Dn,(xxx).L
    
*ILLEGAL INSTRUCTIONS

    SUB.B       (VHEX1,A2),D0   (d16,An),Dn
    SUB.W       (VHEX2,PC),D1   (d16,PC),Dn
    SUB.L       D1, (VHEX1,A1)  Dn,(d16,An)
    
*-----------------------SUBA---------------------------------
* Syntax: <ea>, An
* Size:   W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS

    SUBA.W      D0,A0       Dn,An
    SUBA.L      D1,A1
    
    SUBA.W      A1,A2       An,An
    SUBA.L      A2,A3
    
    SUBA.W      (A3),A3     (An),An
    SUBA.L      (A4),A4
    
    SUBA.W      (A5)+,A0    (An)+,An
    SUBA.L      (A6)+,A1
    
    SUBA.W      -(A0),A2    -(An),An
    SUBA.L      -(A1),A3
    
    SUBA.W      VHEX2,A4    (xxx).W,An
    SUBA.L      VHEX3,A5    (xxx).L,An
    SUBA.L      #VBIN1,A6   #<data>,An
    
*ILLEGAL INSTRUCTIONS

    SUBA.W      ($F0F,A1),A4   (d16,An),An
    SUBA.L      ($1111,PC),A2  (d16,PC),An
    
*-----------------------SUBI----------------------------------
* Syntax: #<data>,<ea>
* Size:   B, W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
    SUBI.B      #VHEX1,D0       #<data>,Dn
    SUBI.W      #VHEX2,D2
    
    SUBI.L      #VHEX3,(A2)       #<data>,(An)
    SUBI.B      #10,(A1)
    
    SUBI.W      #CBITS,(A0)+      #<data>,(An)+
    SUBI.L      #VHEX3,(A2)+
    
    SUBI.B      #10,-(A4)            #<data>,-(An)
    SUBI.W      #$F,-(A1)
    
    SUBI.L      #VHEX2,VHEX2        #<data>,(xxx).W
    SUBI.B      #09,VHEX3        #<data>,(xxx).L
    
*ILLEGAL INSTRUCTIONS

    SUBI.W      #9,($30,A1)         #<data>,(d16,An)
    SUBQ.L      #1,D0           SUBQ
    
   
*----------------------MULU----------------------------------
* Syntax: <ea>,Dn16 x 16, -> 32
* Size:   W
*------------------------------------------------------------

*LEGAL INSTRUCTIONS

    MULU.W      D0,D1           Dn,Dn
    MULU.W      (A0),D1         (An),Dn
    MULU.W      (A2)+,D2        (An)+,Dn
    MULU.W      -(A3),D3        -(An),Dn
    MULU.W      VHEX2,D4        (xxx).W,Dn
    MULU.W      VHEX3,D5        (xxx).L,Dn
    MULU.W      #$2345,D6       #<data>,Dn
    
*ILLEGAL INSTRUCTIONS

    MULU.W      ($32,A2),D0     (d16,An),Dn
    MULU.W      ($1000,PC),D1   (d16,PC),Dn
    
    
*----------------------DIVS----------------------------------
* Syntax: <ea>, Dn32/16
* Size:   W
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
    DIVS.W      D1,D2           Dn,Dn
    DIVS.W      (A1),D2         (An),Dn
    DIVS.W      (A2)+,D3        (An)+,Dn
    DIVS.W      -(A3),D4        -(An),Dn
    DIVS.W      VHEX2,D5        (xxx).W,Dn
    DIVS.W      VHEX3,D6        (xxx).L,Dn
    DIVS.W      #$FF00,D7       #<data>,Dn
    
*ILLEGAL INSTRUCTIONS

    DIVS.W      ($401,A3),D1     (d16,An),Dn
    DIVS.W      ($2211,PC),D2    (d16,PC),Dn
    
   
*-----------------------EOR----------------------------------
* Syntax: Dn,<ea>
* Size:   B, W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
    EOR.B       D0,D1           Dn,Dn
    EOR.W       D1,D2
    
    EOR.L       D2,(A2)         Dn,(An)
    EOR.B       D3,(A3)
    
    EOR.W       D4,(A4)+        Dn,(An)+
    EOR.L       D5,(A5)+
    
    EOR.B       D6,-(A6)        Dn,-(An)
    EOR.W       D7,-(A7)
    
    EOR.L       D0,VHEX2        Dn,(xxx).W
    EOR.B       D1,VHEX3        Dn,(xxx).L

*ILLEGAL INSTRUCTIONS

    EOR.W       D2,($101,A4)    Dn,(d16,An)
    EORI.B      #$1,CCR         EORI to CCR
    
*-----------------------EORI---------------------------------
* Syntax: #<data>,<ea>
* Size:   B, W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS

    EORI.B      #VHEX1,D0       #<data>,Dn
    EORI.W      #10,D1
    
    EORI.L      #VHEX3,(A1)     #<data>,An
    EORI.B      #$12,(A3)
    
    EORI.W      #VHEX2,(A2)+    #<data>,(An)+
    EORI.L      #VBIN1,(A4)+
    
    EORI.B      #$FF, -(A0)     #<data>,-(An)
    EORI.W      #$1222,-(A5)
    
    EORI.L      #VHEX2,VHEX2    #<data>,(xxx).W
    EORI.B      #$11, VHEX3     #<data>,(xxx).L
    
*ILLEGAL INSTRUCTIONS

    EORI.W      #10, ($11,A2)   #<data>,(d16,An)
    EXG.L       D1,D2           EXG
    
*-----------------------AND----------------------------------
* Syntax: <ea>,Dn    -  Dn,<ea>
* Size:   B, W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
*<ea>,Dn

    AND.B       D0,D1           Dn,Dn
    AND.W       (A1),D2         (An),Dn
    AND.L       (A2)+,D3        (An)+,Dn
    AND.B       -(A3),D4        -(An),Dn
    AND.W       VHEX2,D5        (xxx).W,Dn
    AND.L       VHEX3,D6        (xxx).L,Dn
    AND.B       #$FF,D7         #<data>,Dn
    
*Dn,<ea>

    AND.W       D0,(A1)         Dn,(An)
    AND.L       D1,(A2)+        Dn,(An)+
    AND.B       D2,-(A3)        Dn,-(An)
    AND.W       D3,VHEX2        Dn,(xxx).W
    AND.L       D4,VBIN1        Dn,(xxx).L
    
*ILLEGAL INSTRUCTIONS

    AND.B       ($12,A2),D2     (d16,An),Dn
    AND.W       ($1121,PC),D3   (d16,PC),Dn
    AND.L       D4, ($112,A4)   Dn,(d16,An)
    
*-----------------------ORI----------------------------------
* Syntax: #<data>,<ea>
* Size:   B, W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
    ORI.B       #$F1,D0         #<data>,Dn
    ORI.W       #VHEX2,(A2)     #<data>,(An)
    ORI.L       #VHEX3,(A3)+    #<data>,(An)+
    ORI.B       #$11,-(A4)      #<data>,-(An)
    ORI.W       #98,VHEX2       #<data>,(xxx).W
    ORI.L       #100,VHEX3      #<data>,(xxx).L
    
*ILLEGAL INSTRUCTIONS

    ORI.B       #4,($FF,A2)     #<data>,(d16,An)
    OR.W        D1,D2           OR
    
*----------------------ASL-----------------------------------
* Syntax: Dx,Dy  - #<data>,Dy   -   <ea>
* Size:   B, W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
    ASL.B       D0,D1       Dx,Dy
    ASL.W       D2,D2       
    ASL.L       #4,D2       #<data>,Dy
    ASL.W       (A2)        (An)
    ASL.W       (A3)+       (An)+
    ASL.W       -(A4)       -(An)
    ASL.W       VHEX2       (xxx).W
    ASL.W       VHEX3       (xxx).L
    
*ILLEGAL INSTRUCTIONS

    ASL.W       ($22,A4)    (d16,An)
    ASR.W       VHEX2       ASR
    
*-----------------------LSR----------------------------------
* Syntax: Dx,Dy  - #<data>,Dy   -   <ea>
* Size:   B, W, L
*------------------------------------------------------------
*LEGAL INSTRUCTIONS
    LSR.B       D0,D1       Dx,Dy
    LSR.W       D2,D2       
    LSR.L       #4,D2       #<data>,Dy
    LSR.W       (A2)        (An)
    LSR.W       (A3)+       (An)+
    LSR.W       -(A4)       -(An)
    LSR.W       VHEX2       (xxx).W
    LSR.W       VHEX3       (xxx).L
    
*ILLEGAL INSTRUCTIONS

    LSR.W       ($22,A4)    (d16,An)
    LSL.W       VHEX2       LSL
    
*----------------------BTST----------------------------------
* Syntax: Dn, <ea>  - #<data>,<ea>
* Size:   B, L
*------------------------------------------------------------
*LEGAL INSTRUCTIONS
*Dn, <ea>

    BTST.L      D0, D1      Dn,Dn
    BTST.B      D1,(A1)     Dn,(An)
    BTST.B      D2,(A2)+    Dn,(An)+
    BTST.B      D3,-(A3)    Dn,-(An)
    BTST.B      D4,VHEX2    Dn,(xxx).W
    BTST.B      D5,VHEX4    Dn,(xxx).L
    BTST.B      D6,#4       Dn,#<data>
    
*#<data>,<ea>

    BTST.L      #VHEX2,D0       #<data>,Dn
    BTST.B      #VHEX1,(A0)     #<data>,(An)
    BTST.B      #VHEX3,(A0)+    #<data>,(An)+
    BTST.B      #VBIN1,-(A4)    #<data>,-(An)
    BTST.B      #$11,VHEX2      #<data>,(xxx).W
    BTST.B      #$99,VHEX3      #<data>,(xxx).L
    
*ILLEGAL INSTRUCTIONS

    BTST.B      D7, ($11,A3)    Dn,(d16,An)
    BTST.B      D6, ($AA,PC)    Dn,(d16,PC)
    BTST.B      #1111,($BB,A2)  #<data>,(d16,An)
    
*-----------------------CMP + Bcc----------------------------
* Syntax: <ea>,Dn
* Size:   B, W, L
*------------------------------------------------------------
*LEGAL INSTRUCTIONS
    CMP.B       D1,D0       Dn,Dn
    BEQ         B1a
B1a    
    CMP.W       A2,D1       An,Dn
    BEQ         B2a
B2a
    CMP.L       (A3),D2     (An),Dn
    BLT         B3
B3
    CMP.B       (A4)+,D3    (An)+,Dn
    BNE         B4
B4
    CMP.W       -(A5),D4    -(An),Dn
    BHI         B5
B5
    CMP.L       VHEX2,D5    (xxx).W,Dn
    CMP.B       VHEX3,D6    (xxx).L,Dn
    CMP.L       #VBIN1,D7   #<data>,Dn

*ILLEGAL INSTRUCTIONS

    CMP.B       ($FF,A0),D0     (d16,An),Dn
    CMP.W       ($CC1,PC),D2    (d16,PC),Dn
    
*-----------------------CMPA + Bcc---------------------------
* Syntax: <ea>,An
* Size:    W, L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
    CMPA.W      D0,A0       Dn,An
    CMPA.L      A0,A1       An,An
    BEQ         Ba1
Ba1
    CMPA.W      (A1),A2     (An),An
    BLT         Ba2
Ba2
    CMPA.L      (A2)+,A3    (An)+,An
    BNE         Ba3
Ba3
    CMPA.W      -(A3),A4    -(An),An
    BHI         Ba4
Ba4
    CMPA.L      VHEX2,A5    (xxx).W,An
    CMPA.W      VHEX3,A6    (xxx).L,An
    CMPA.L      #1234,A7    #<data>,An
    
*ILLEGAL INSTRUCTIONS

    CMPA.W      ($33,A1),A0     (d16,An),An
    CMPA.L      ($11,PC),A2     (d16,PC),An
    
*-----------------------CMPI + Bcc---------------------------
* Syntax: #<data>,<ea>
* Size:   B, W, L
*------------------------------------------------------------
*LEGAL INSTRUCTIONS

    CMPI.B      #VHEX1,D0       #<data>,Dn
    BEQ         Bb1
Bb1
    CMPI.W      #VHEX2,(A1)     #<data>,(An)
    BNE         Bb2
Bb2
    CMPI.L      #VHEX3,(A2)+    #<data>,(An)+
    BHI         Bb3
Bb3
    CMPI.B      #$12,-(A3)      #<data>,-(An)
    BLT         Bb4
    CMPI.W      #$1234,VHEX2    #<data>,(xxx).W
Bb4
    CMPI.L      #VBIN1,VHEX3    #<data>,(xxx).L
    
*ILLEGAL INSTRUCTIONS

    CMPI.B      #$FF,($99,A2)       #<data>,(d16,An)
    CMPM.B      (A2)+,(A1)+         CMPM
    
*-----------------------LEA----------------------------------
* Syntax: <ea>,An
* Size:   L
*------------------------------------------------------------

*LEGAL INSTRUCTIONS
    LEA     (A1),A0         (An),An
    LEA     VHEX2,A1        (xxx).W,An
    LEA     VHEX3,A2        (xxx).L,An
 
*ILLEGAL INSTRUCTIONS

    LEA     ($10,A1),A1     (d16,An),An
    LEA     ($999,PC),A2    (d16,PC),An
    
*-----------------------JSR----------------------------------
* Syntax: <ea>
* Size:   Unsized
*------------------------------------------------------------
*LEGAL INSTRUCTIONS
    JSR     JUMP
    JSR     (A1)        (An)
    JSR     VHEX2       (xxx).W
    JSR     VHEX3       (xxx).L
*ILLEGAL INSTRUCTIONS
    JSR     ($19,A2)    (d16,An)
    JSR     ($100,PC)   (d16,PC)
    
*-----------------------RTS----------------------------------
* Syntax: 
* Size:   Unsized
*------------------------------------------------------------
*LEGAL INSTRUCTIONS
JUMP    *For JSR & RTS test
        MOVE.B  D1, D1
        RTS
*ILLEGAL INSTRUCTIONS
        NOP         NOP

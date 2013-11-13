*----------------------------------------------------------------------------
* Title      : 3B Disassembler
* Written by : The Three Bears: Joseph Schooley, Nguyen Tong, Terence Calhoun
* Date       : 11/11/2013
* Description: A Motorola MC68000 Microprocessor Disassembler 
*----------------------------------------------------------------------------
CR      EQU     $0D             ASCII: carriage return
LF      EQU     $0A             ASCII: line feed
TB      EQU     $09             ASCII: horizontal tab
OADDR   EQU     $1000           Org address
MNADDR  EQU     $7000           Min address
MXADDR  EQU     $8000           Max address
BYTES   EQU     10000           Number of bytes to read from file
SLOC    DS.B    4               Starting location storage
ELOC    DS.B    4               Ending location storage
EA_REG  DS.B    2               ;Storage for EA-Reg
EA_MODE DS.B    2               ;Storage for EA-Mode
OP_MODE DS.B    2               ;Storage for OP-Mode
INS_REG DS.B    2               ;Storage for Regiser Number

*----MASKS(SHOW)-------
BIT_34  EQU     %0000000000011000 ;used to show bits 3,4
BIT_5   EQU     %0000000000100000 ;used to show bit 5
BIT_67  EQU     %0000000011000000 ;used to show bits 6,7
BIT_8   EQU     %0000000100000000 ;used to show bit 8
BIT_012 EQU     %0000000000000111 ;used to show bits 0,1,2
BIT_345 EQU     %0000000000111000 ;used to show bits 3,4,5
BIT_678 EQU     %0000000111000000 ;used to show bits 8,7,6
BIT_91011 EQU   %0000111000000000 ;used to show bits 9,10,11
BIT_12131415 EQU %1111000000000000 ;used to show bits 12,13,14,15

*----MASKS(DONTSHOW)------
*USE NOT on the bits above
MSSG0   DC.B    '  _     _     _     _     _     _ ',CR,LF
        DC.B    ' (o\---/o)   (o\---/o)   (o\---/o)',CR,LF
        DC.B    '  | - - |     | ^ ^ |     | . . |',CR,LF
        DC.B    ' _( (Y)_)_,--.(_(Y)_),--._(_(Y) )_',CR,LF
        DC.B    '/ /___|_  ".."       ".."  _|___\ \',CR,LF
        DC.B    '\_______):     THREE     :(_______/',CR,LF
        DC.B    '| |   |        BEARS        |   | |',CR,LF
        DC.B    '| |   |    DISASSEMBLER     |   | |',CR,LF
        DC.B    '|  \__|_____________________|__/  |',CR,LF
        DC.B    ' \    I  /_  )   |   (  _\  I    /',CR,LF
        DC.B    '  \____)___)(___/ \___)(___(____/',CR,LF
        DC.B    'Welcome to 3B Disassembler. Enter 0 at any time to quit.',CR,LF,0
MSSG1   DC.B    'Enter the starting location of the code to be disassembled:',0
MSSG2   DC.B    'Enter the ending location of the code to be disassembled:',0
MSSG3   DC.B    'Enter the name of the file you wish to disassemble:',0
HEADR   DC.B    'Address    Code        Line',CR,LF,0
ERR0    DC.B    'The input address was too small.',CR,LF,0
ERR1    DC.B    'The input address was too big.',CR,LF,0

        ORG     OADDR

START

        LEA     MSSG0,A1        Welcome message
        MOVE.B  #14,D0
        TRAP    #15
        
        BRA     PRMPT0
        
*-----------------------------------
*    Conversion & Comparison Methods
*-----------------------------------

*
* Flag clear / set: Assumes original value in D1 was stored as a long.
* Restores the value and clears / sets the flag in D1.B, then returns to the caller
*

FLAGCL  MOVE.L  (SP)+,D1        Restore D1
        MOVE.B  #$FF,D1         Clear the flag
        RTS                     Return to caller
        
FLAGST  MOVE.L  (SP)+,D1        Restore D1
        MOVE.B  #$11,D1         Set the flag
        RTS                     Return to caller

*
* ASCII2HEX: Convert ASCII into HEX.
* Input ASCII from D0 output HEX to D1
*

ASCII2HEX
        MOVE.L  D0,D1           Move the input to D1
        SUB     #$3030,D1       Convert last word
        SWAP    D1              Swap bytes
        SUB     #$3030,D1       Convert first word
        SWAP    D1              Restore order
        
        MOVE.L  D2,-(SP)        Push D2 on stack
        CLR.L   D2              
        MOVE.B  #3,D2           Set rotation count
        
        BSR     A2H             Start loop
        
        MOVE.L  (SP)+,D2        Restore D2
                
        ROL.B   #4,D1           XAXBXCDX
        LSL.W   #4,D1           XAXBCDX0
        ROL.W   #8,D1           XAXBX0CD
        SWAP    D1              X0CDXAXB
        ROL.B   #4,D1           X0CDXABX
        LSL.W   #4,D1           X0CDABX0
        LSL.L   #8,D1           CDABX000
        CLR.W   D1              CDAB0000
        SWAP    D1              0000CDAB
        ROL.W   #8,D1           0000ABCD
        RTS                     Return to caller
        
        
A2H   * ASCII2HEX helper: Convert bytes that were > 30 to appropriate HEX value
        CMP.B   #$11,D1         11 = A
        BEQ     A2H11
        CMP.B   #$12,D1         12 = B
        BEQ     A2H12
        CMP.B   #$13,D1         13 = C
        BEQ     A2H13
        CMP.B   #$14,D1         14 = D
        BEQ     A2H14
        CMP.B   #$15,D1         15 = E
        BEQ     A2H15
        CMP.B   $16,D1          16 = F
        BEQ     A2H16
        
A2HADV  * A2H conversion branch helper: Rotate to the next byte, and loop back to A2H until all bytes have been analyzed/converted
        ROL.L   #8,D1           Rotate 1st byte to the end
        DBRA    D2,A2H          If count is > 0, decrement and loop back to A2H
        RTS                     If count == 0, return to sub-routine

* A2H conversion branches
A2H11   MOVE.B  #$A,D1
        BRA     A2HADV
A2H12   MOVE.B  #$B,D1
        BRA     A2HADV
A2H13   MOVE.B  #$C,D1
        BRA     A2HADV
A2H14   MOVE.B  #$D,D1
        BRA     A2HADV
A2H15   MOVE.B  #$E,D1
        BRA     A2HADV
A2H16   MOVE.B  #$F,D1
        BRA     A2HADV
        

*
* Mask: Test an input to a mask.
* Input value from D0, input mask from D2, and output clear/set flag in D1.B as #$11/#$FF
*

MASK    MOVE.L  D1,-(SP)        Push D1 on stack
        MOVE.L  D0,D1           Move the input to D1
        AND.L   D2,D1           Perform AND on input with the mask
        SUB.L   D2,D1           Mask - masked input
        TST     D1              Test the difference for 0
        BEQ     FLAGST          If it is 0, the input matched the mask; set the flag and return to the caller
        BRA     FLAGCL          If it is not 0, the input did not match the mask; clear the flag and return to the caller
        
*
* Extract: Test an input to a subsequent mask, and return the masked value in LSB format
* Input value from D0, input mask from D2, output value in D2
*

EXT     MOVE.L  D2,-(SP)    Push D2 on stack
        MOVE.L  D0,D1       Move the input to D1
        AND.L   D2,D1       Perform AND on input with the mask
EXTLP   BTST.L  #0,D2       Test the LSB of the mask for 0
        BEQ     EXTADV      If it is 0, rotate the mask until it is 1
        MOVE.L  (SP)+,D2    Restore the mask
        RTS                 Return to caller
        
EXTADV  LSR.L   #1,D2       Rotate mask right by 1 bit
        ROR.L   #1,D1       Rotate output in sync with mask
        BRA     EXTLP       Return to loop
        
*--------------------
*   I/O
*--------------------

PRMPT0  LEA     MSSG3,A1        File name request message
        MOVE.B  #14,D0
        TRAP    #15
                
        MOVE.B  #2,D0           Input file name
        TRAP    #15

        MOVE    #51,D0          Open file
        TRAP    #15
        
        LEA     MNADDR,A1       Read file data from starting location
        MOVE    #BYTES,D2       Set bytes to read (max)
        MOVE    #53,D0          Read from file
        TRAP    #15
        
        BRA     PRMPT1
           
ILL0    LEA     ERR0,A1         Starting location was too small
        MOVE.B  #14,D0
        TRAP    #15
        BRA     PRMPT1
        
ILL1    LEA     ERR1,A1         Starting location was too big
        MOVE.B  #14,D0
        TRAP    #15
        
PRMPT1  LEA     MSSG1,A1        Starting location request message
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     SLOC,A1         Input will be stored in SLOC
        MOVE.B  #2,D0           Input starting location (as string / hex)
        TRAP    #15
        
        MOVE.L  (SLOC),D0       Move input to D0
        
        BSR     ASCII2HEX       Convert D0 to HEX
        
        CLR.L   (A1)            Clear SLOC storage
        MOVE    D1,(A1)         Set first byte of SLOC to HEX value
                        
        CMP.W   #0,D1           Compare starting location to 0
        BEQ     DONE            End program if 0
        
        CMP.W   #MNADDR,D1      Compare starting location to min
        BLO     ILL0            Branch to ILL0 if < min
        
        CMP.W   #MXADDR,D1      Compare ending location to max
        BHS     ILL1            Branch to ILL1 if >= max
                
        BRA     PRMPT2

ILL2    LEA     ERR0,A1         Ending location was too small
        MOVE.B  #14,D0
        TRAP    #15
        BRA     PRMPT2
        
ILL3    LEA     ERR1,A1         Ending location was too big
        MOVE.B  #14,D0
        TRAP    #15
        
PRMPT2  LEA     MSSG2,A1        Ending location request message
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     ELOC,A1         Input will be stored in SLOC
        MOVE.B  #2,D0           Input starting location (as string / hex)
        TRAP    #15
        
        MOVE.L  (ELOC),D0       Move input to D1
        
        BSR     ASCII2HEX       Convert D0 to HEX and continue
        
        CLR.L   (A1)            Clear ELOC storage
        MOVE    D1,(A1)         Set first byte of ELOC to HEX value

        CMP.W   #0,D1           Compare ending location to 0
        BEQ     DONE            End program if 0
        
        CMP.W   #MNADDR,D1      Compare min ending location to min
        BLS     ILL2            Branch to ILL2 if <= min
        
        CMP.W   #MXADDR,D1      Compare ending location to max
        BHI     ILL3            Branch to ILL3 if > max
        
        MOVE.B  (SLOC),D0       Move starting location data to D0
        CMP.W   D0,D1           Compare ending location to starting location
        BLS     ILL2            Branch to ILL3 if <= starting location
        
        BRA     OP
        
DONE    MOVE.B  #9,D0
        TRAP    #15
        
*--------------------
*   OP
*--------------------

OP      MOVEA.W SLOC,A0         Load address register
        MOVE.L  (A0),D0         Transfer data to memory
        BSR     ASCII2HEX
        MOVE.L  D1,D0           Replace value with HEX value

LOOP1   CMP.W   ELOC,A0         Compare ending location to location
        BGE     DONE            Branch to DONE if <= to location
        
        * Mask bits to determine OP-code and branch correspondingly-- high order bits are checked first
        
		MOVE.L	#%1110000010001000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRLSR

		MOVE.L	#%1110000001001000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRLSR

		MOVE.L	#%1110000000001000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRLSR

		MOVE.L	#%1110000010000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRASL

		MOVE.L	#%1110000001000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRASL

		MOVE.L	#%1110000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRASL

		MOVE.L	#%1101000111000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRADDA

		MOVE.L	#%1101000011000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRADDA

		MOVE.L	#%1101000110000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRADD

		MOVE.L	#%1101000101000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRADD

		MOVE.L	#%1101000100000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRADD

		MOVE.L	#%1101000010000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRADD

		MOVE.L	#%1101000001000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRADD

		MOVE.L	#%1101000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRADD

		MOVE.L	#%1100000110000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRAND

		MOVE.L	#%1100000101000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRAND

		MOVE.L	#%1100000100000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRAND

		MOVE.L	#%1100000010000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRAND

		MOVE.L	#%1100000001000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRAND

		MOVE.L	#%1100000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRAND

		MOVE.L	#%1100000011000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRMULU

		MOVE.L	#%1011000111000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRCMPA

		MOVE.L	#%1011000011000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRCMPA

		MOVE.L	#%1011000010000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRCMP

		MOVE.L	#%1011000001000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRCMP

		MOVE.L	#%1011000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRCMP

		MOVE.L	#%1011000110000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BREOR

		MOVE.L	#%1011000101000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BREOR

		MOVE.L	#%1011000100000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BREOR

		MOVE.L	#%1001000111000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRSUBA

		MOVE.L	#%1001000011000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRSUBA

		MOVE.L	#%1001000110000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRSUB

		MOVE.L	#%1001000101000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRSUB

		MOVE.L	#%1001000100000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRSUB

		MOVE.L	#%1001000010000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRSUB

		MOVE.L	#%1001000001000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRSUB

		MOVE.L	#%1001000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRSUB

		MOVE.L	#%1000000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRDIVS

		MOVE.L	#%0110000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRBCC

		MOVE.L	#%0101000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRADDQ

		MOVE.L	#%0100111001000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRRTS

		MOVE.L	#%0100111010000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRJSR

		MOVE.L	#%0100110100000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRNOT

		MOVE.L	#%0100110010000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRNOT

		MOVE.L	#%0100110000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRNOT

		MOVE.L	#%0100000111000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRLEA

		MOVE.L	#%0100110011000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRMOVEM

		MOVE.L	#%0100110010000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRMOVEM

		MOVE.L	#%0100100011000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRMOVEM

		MOVE.L	#%0100100010000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRMOVEM

		MOVE.L	#%0011000001000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRMOVEA

		MOVE.L	#%0011000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRMOVE

		MOVE.L	#%0010000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRMOVE

		MOVE.L	#%0010000000010000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRMOVEA

		MOVE.L	#%0001000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRMOVE

		MOVE.L	#%0000110000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRCMPI

		MOVE.L	#%0000000100000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRBTST

		MOVE.L	#%0000101000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BREORI

		MOVE.L	#%0000000000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRORI

		MOVE.L	#%0000010000000000,D2
		BSR		MASK
		CMP.B	#$11,D1
		BEQ		BRSUBI
		
		BRA     BAD                 No mask matched, branch to BAD

INCREM  MOVE.L  (A0)+,D0            Post-Increment location to memory
        BSR     ASCII2HEX
        MOVE.L  D1,D0               Replace value with HEX value
        BRA     LOOP1               Loop back until ending location is reach
        
BAD     BRA     INCREM
BRSUBI	BRA		INCREM
BRORI   BRA		INCREM
BREORI	BRA		INCREM
BRBTST	BRA		INCREM
BRCMPI	BRA		INCREM
BRMOVE	BRA		INCREM
BRMOVEA	BRA		INCREM
BRMOVEM	BRA		INCREM
BRLEA	BRA		INCREM
BRNOT	BRA		INCREM
BRJSR	BRA		INCREM
BRADDQ	BRA		INCREM
BRBCC	BRA		INCREM
BRDIVS	BRA		INCREM
BRSUB	BRA		INCREM
BRSUBA	BRA		INCREM
BREOR	BRA		INCREM
BRCMP	BRA		INCREM
BRCMPA	BRA		INCREM
BRMULU	BRA		INCREM
BRAND	BRA		INCREM
BRADD	BRA		INCREM
BRADDA	BRA		INCREM
BRASL	BRA		INCREM
BRLSR	BRA		INCREM
        
*--------------------
*   EA
*--------------------


*--------------------------
*  Instruction Subroutines
*--------------------------
BRRTS 
*       LEA     _RTS, A1        ;load 'RTS' to be printed
*       MOVE    _RTS_len, D1    ;load the length of message
*       JSR     printONE        ;send to 1st print function
        RTS                     ;Return to subroutine


*----------------------------------------------
*   Get OP_Mode, EA_Mode, EA_Register, Register
*----------------------------------------------
GET_OP_MODE
*       MOVE.L  Dn, Dn          ;copy bits
*       AND.L   #BIT_678, Dn    ;show only 6,7,8
*       LSR.L   #6, Dn          ;shift the bits over
*       MOVE.B  Dn, OP_MODE     ;Copy into OP_MODE Variable
        RTS                     ;Return back to return to subroutine

GET_EA_REG
*       MOVE.L  Dn, Dn          ;copy bits
*       AND.L   #BIT_012, Dn    ;show only 0,1,2
*       MOVE.B  Dn, EA_REG      ;Copy into REGISTER Variable
        RTS                     ;Return back to return to subroutine
        
GET_EA_MODE
*       MOVE.L  Dn, Dn          ;copy bits
*       AND.L   #BIT_345, Dn    ;show only 3,4,5
*       LSR.L   #3, Dn          ;shift the bits over
*       MOVE.B  Dn, EA_MODE     ;Copy into EA_MODE Variable
        RTS                     ;Return back to return to subroutine
        
GET_REGISTER
*       MOVE.L  Dn, Dn          ;copy bits
*       AND.L   #BIT_91011, Dn  ;show only 9,10,11
*       LSR.L   #5, Dn          ;shift the bits over
*       LSR.L   #4, Dn          ;shift again
*       MOVE.B  Dn, INS_REG     ;Copy into REGISTER Variable
        RTS                     ;Return back to return to subroutine

goToD0 
goToD1 
goToD2 
goToD3 
goToD4 
goToD5
goToD6 
goToD7 
goToA0 
goToA1 
goToA2 
goToA3 
goToA4 
goToA5
goToA6 
goToA7 
  

goToEA_Mode0000 
goToEA_Mode0001 
goToEA_Mode0010 
goToEA_Mode0011 
goToEA_Mode0100 
goToEA_Mode0101 
goToEA_Mode0110 
goToEA_Mode0111 


goToOP_Mode0000 
goToOP_Mode0001 
goToOP_Mode0010 
goToOP_Mode0011 
goToOP_Mode0100 
goToOP_Mode0101 
goToOP_Mode0110 
goToOP_Mode0111 

*---------------------------
*   TABLES:
*   REGISTER:   (D0-D7 and A0-A7)
*   OPmodes:    (Modes 000-111)
*   EAmodes:    (Modes 000-111)
*   MANIP:      (...)    

*---------------------------
*   Register Table
*   0000-0111 = D0-D7
*   1000-1111 = A0-A7
*---------------------------
REG_TBL     JMP     goToD0 ;0000
            JMP     goToD1 ;0001
            JMP     goToD2 ;0010
            JMP     goToD3 ;0011
            JMP     goToD4 ;0100
            JMP     goToD5 ;0101
            JMP     goToD6 ;0110
            JMP     goToD7 ;0111
            JMP     goToA0 ;1000
            JMP     goToA1 ;1001
            JMP     goToA2 ;1010
            JMP     goToA3 ;1011
            JMP     goToA4 ;1100
            JMP     goToA5 ;1101
            JMP     goToA6 ;1110
            JMP     goToA7 ;1111
            
*-----------------------------
*   EA Table
*   MODES (0000-0111)
*-----------------------------
EA_TBL      JMP     goToEA_Mode0000 ;0000
            JMP     goToEA_Mode0001 ;0001
            JMP     goToEA_Mode0010 ;0010
            JMP     goToEA_Mode0011 ;0011
            JMP     goToEA_Mode0100 ;0100
            JMP     goToEA_Mode0101 ;0101
            JMP     goToEA_Mode0110 ;0110
            JMP     goToEA_Mode0111 ;0111
            
*-----------------------------
*   OP Mode Table
*   MODES (0000-0111)
*-----------------------------
OP_TBL      JMP     goToOP_Mode0000 ;0000
            JMP     goToOP_Mode0001 ;0001
            JMP     goToOP_Mode0010 ;0010
            JMP     goToOP_Mode0011 ;0011
            JMP     goToOP_Mode0100 ;0100
            JMP     goToOP_Mode0101 ;0101
            JMP     goToOP_Mode0110 ;0110
            JMP     goToOP_Mode0111 ;0111
        BRA     DONE
        
        END     START






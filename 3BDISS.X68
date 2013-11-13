*----------------------------------------------------------------------------
* Title      : 3B Disassembler
* Written by : The Three Bears: Joseph Schooley, Nguyen Tong, Terence Calhoun
* Date       : 11/11/2013
* Description: A Motorola MC68000 Microprocessor Disassembler 
*----------------------------------------------------------------------------
CR      EQU     $0D     ASCII: carriage return
LF      EQU     $0A     ASCII: line feed
TB      EQU     $09     ASCII: horizontal tab
OADDR   EQU     $1000   Org address
MNADDR  EQU     $7000   Min address
MXADDR  EQU     $FFFFF0 Max address
BYTES   EQU     10000   Number of bytes to read from file
SLOC    DS.B    4       Starting location storage
ELOC    DS.B    4       Ending location storage
MSK_012 DS.B    1       Storage for bits 0,1,2
MSK_345 DS.B    1       Storage for bits 3,4,5
MSK_5   DS.B    1       Storage for bit 5
MSK_678 DS.B    1       Storage for bits 6,7,8
MSK_9AB DS.B    1       Storage for bits 9,10,11
MSK_CD  DS.B    1       Storage for bits 12,13
MODE    DS.B    1       Storage for which bits to use EA or OP

*----Words--------------
_RTS    DC.B    'RTS',CR,LF,0
_M0     DC.B    'MODE 000',CR,LF,0
_M1     DC.B    'MODE 001',CR,LF,0
_M2     DC.B    'MODE 010',CR,LF,0
_M3     DC.B    'MODE 011',CR,LF,0
_M4     DC.B    'MODE 100',CR,LF,0
_M5     DC.B    'MODE 101',CR,LF,0
_M6     DC.B    'MODE 110',CR,LF,0
_M7     DC.B    'MODE 111',CR,LF,0

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
* Mask: Mask an input
* Input value from D1, input mask from D2, output masked value to D1
*

MASK    MOVE.L  D0,D1           Move the input to D1
        AND.L   D2,D1           Perform AND on input with the mask
        RTS                     Return to caller

*
* Test Mask: Test an input to a mask.
* Input value from D0, input mask from D2, and modify z-flag
*

TSTMSK  MOVE.L  D1,-(SP)        Push D1 on stack
        BSR     MASK            Mask the input
        SUB.L   D2,D1           Mask - masked input
        CMP.L   #0,D1           Test the difference for 0
        BEQ     FLAGST          If it is 0, the input matched the mask; set the z-flag and return to the caller
        * If it is not 0, the input did not match the mask; clear the z-flag and return to the caller
FLAGCL  MOVE.L  (SP)+,D1        Restore D1
        MOVE    #%000,CCR       Set the z-flag
        RTS                     Return to caller
FLAGST  MOVE.L  (SP)+,D1        Restore D1
        MOVE    #%100,CCR       Set the z-flag
        RTS                     Return to caller
        
       
* Extract Mask: Test an input to a subsequent mask, and return the masked value in LSB format
* Input value from D0, input mask from D2, output value in D2
*

EXTMSK  MOVE.L  D2,-(SP)        Push D2 on stack
        MOVE.L  D0,D1           Move the input to D1
        AND.L   D2,D1           Perform AND on input with the mask
EXTLP   BTST.L  #0,D2           Test the LSB of the mask for 0
        BEQ     EXTADV          If it is 0, rotate the mask until it is 1
        MOVE.L  (SP)+,D2        Restore the mask
        RTS                     Return to caller
        
EXTADV  LSR.L   #1,D2           Rotate mask right by 1 bit
        ROR.L   #1,D1           Rotate output in sync with mask
        BRA     EXTLP           Return to loop
        
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
        MOVE.L  D1,(A1)         Set SLOC to HEX value
                        
        CMP.L   #0,D1           Compare starting location to 0
        BEQ     DONE            End program if 0
        
        CMP.L   #MNADDR,D1      Compare starting location to min
        BLO     ILL0            Branch to ILL0 if < min
        
        CMP.L   #MXADDR,D1      Compare ending location to max
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
        MOVE.L  D1,(A1)         Set ELOC to HEX value

        CMP.L   #0,D1           Compare ending location to 0
        BEQ     DONE            End program if 0
        
        CMP.L   #MNADDR,D1      Compare min ending location to min
        BLS     ILL2            Branch to ILL2 if <= min
        
        CMP.L   #MXADDR,D1      Compare ending location to max
        BHI     ILL3            Branch to ILL3 if > max
        
        MOVE.L  (SLOC),D0       Move starting location data to D0
        CMP.L   D0,D1           Compare ending location to starting location
        BLS     ILL2            Branch to ILL3 if <= starting location
        
        BRA     OP
        
DONE    MOVE.B  #9,D0
        TRAP    #15

*--------------------
*   OP
*--------------------

OP      MOVEA.L SLOC,A0         Load address register
        MOVE.L  (A0),D0         Transfer data to memory
        BSR     ASCII2HEX
        MOVE.L  D1,D0           Replace value with HEX value

LOOP1   CMP.L   ELOC,A0         Compare ending location to location
        BGE     DONE            Branch to DONE if <= to location
        
        * Mask bits to determine OP-code and branch correspondingly-- high order bits are checked first
        
		MOVE.L	#%1110000010001000,D2
		BSR		TSTMSK
		BEQ		BRLSR

		MOVE.L	#%1110000001001000,D2
		BSR		TSTMSK
		BEQ		BRLSR

		MOVE.L	#%1110000000001000,D2
		BSR		TSTMSK
		BEQ		BRLSR

		MOVE.L	#%1110000010000000,D2
		BSR		TSTMSK
		BEQ		BRASL

		MOVE.L	#%1110000001000000,D2
		BSR		TSTMSK
		BEQ		BRASL

		MOVE.L	#%1110000000000000,D2
		BSR		TSTMSK
		BEQ		BRASL

		MOVE.L	#%1101000111000000,D2
		BSR		TSTMSK
		BEQ		BRADDA

		MOVE.L	#%1101000011000000,D2
		BSR		TSTMSK
		BEQ		BRADDA

		MOVE.L	#%1101000110000000,D2
		BSR		TSTMSK
		BEQ		BRADD

		MOVE.L	#%1101000101000000,D2
		BSR		TSTMSK
		BEQ		BRADD

		MOVE.L	#%1101000100000000,D2
		BSR		TSTMSK
		BEQ		BRADD

		MOVE.L	#%1101000010000000,D2
		BSR		TSTMSK
		BEQ		BRADD

		MOVE.L	#%1101000001000000,D2
		BSR		TSTMSK
		BEQ		BRADD

		MOVE.L	#%1101000000000000,D2
		BSR		TSTMSK
		BEQ		BRADD

		MOVE.L	#%1100000110000000,D2
		BSR		TSTMSK
		BEQ		BRAND

		MOVE.L	#%1100000101000000,D2
		BSR		TSTMSK
		BEQ		BRAND

		MOVE.L	#%1100000100000000,D2
		BSR		TSTMSK
		BEQ		BRAND

		MOVE.L	#%1100000010000000,D2
		BSR		TSTMSK
		BEQ		BRAND

		MOVE.L	#%1100000001000000,D2
		BSR		TSTMSK
		BEQ		BRAND

		MOVE.L	#%1100000000000000,D2
		BSR		TSTMSK
		BEQ		BRAND

		MOVE.L	#%1100000011000000,D2
		BSR		TSTMSK
		BEQ		BRMULU

		MOVE.L	#%1011000111000000,D2
		BSR		TSTMSK
		BEQ		BRCMPA

		MOVE.L	#%1011000011000000,D2
		BSR		TSTMSK
		BEQ		BRCMPA

		MOVE.L	#%1011000010000000,D2
		BSR		TSTMSK
		BEQ		BRCMP

		MOVE.L	#%1011000001000000,D2
		BSR		TSTMSK
		BEQ		BRCMP

		MOVE.L	#%1011000000000000,D2
		BSR		TSTMSK
		BEQ		BRCMP

		MOVE.L	#%1011000110000000,D2
		BSR		TSTMSK
		BEQ		BREOR

		MOVE.L	#%1011000101000000,D2
		BSR		TSTMSK
		BEQ		BREOR

		MOVE.L	#%1011000100000000,D2
		BSR		TSTMSK
		BEQ		BREOR

		MOVE.L	#%1001000111000000,D2
		BSR		TSTMSK
		BEQ		BRSUBA

		MOVE.L	#%1001000011000000,D2
		BSR		TSTMSK
		BEQ		BRSUBA

		MOVE.L	#%1001000110000000,D2
		BSR		TSTMSK
		BEQ		BRSUB

		MOVE.L	#%1001000101000000,D2
		BSR		TSTMSK
		BEQ		BRSUB

		MOVE.L	#%1001000100000000,D2
		BSR		TSTMSK
		BEQ		BRSUB

		MOVE.L	#%1001000010000000,D2
		BSR		TSTMSK
		BEQ		BRSUB

		MOVE.L	#%1001000001000000,D2
		BSR		TSTMSK
		BEQ		BRSUB

		MOVE.L	#%1001000000000000,D2
		BSR		TSTMSK
		BEQ		BRSUB

		MOVE.L	#%1000000000000000,D2
		BSR		TSTMSK
		BEQ		BRDIVS

		MOVE.L	#%0110000000000000,D2
		BSR		TSTMSK
		BEQ		BRBCC

		MOVE.L	#%0101000000000000,D2
		BSR		TSTMSK
		BEQ		BRADDQ

		MOVE.L	#%0100111001000000,D2
		BSR		TSTMSK
		BEQ		BRRTS

		MOVE.L	#%0100111010000000,D2
		BSR		TSTMSK
		BEQ		BRJSR

		MOVE.L	#%0100110100000000,D2
		BSR		TSTMSK
		BEQ		BRNOT

		MOVE.L	#%0100110010000000,D2
		BSR		TSTMSK
		BEQ		BRNOT

		MOVE.L	#%0100110000000000,D2
		BSR		TSTMSK
		BEQ		BRNOT

		MOVE.L	#%0100000111000000,D2
		BSR		TSTMSK
		BEQ		BRLEA

		MOVE.L	#%0100110011000000,D2
		BSR		TSTMSK
		BEQ		BRMOVEM

		MOVE.L	#%0100110010000000,D2
		BSR		TSTMSK
		BEQ		BRMOVEM

		MOVE.L	#%0100100011000000,D2
		BSR		TSTMSK
		BEQ		BRMOVEM

		MOVE.L	#%0100100010000000,D2
		BSR		TSTMSK
		BEQ		BRMOVEM

		MOVE.L	#%0011000001000000,D2
		BSR		TSTMSK
		BEQ		BRMOVEA

		MOVE.L	#%0011000000000000,D2
		BSR		TSTMSK
		BEQ		BRMOVE

		MOVE.L	#%0010000000000000,D2
		BSR		TSTMSK
		BEQ		BRMOVE

		MOVE.L	#%0010000000010000,D2
		BSR		TSTMSK
		BEQ		BRMOVEA

		MOVE.L	#%0001000000000000,D2
		BSR		TSTMSK
		BEQ		BRMOVE

		MOVE.L	#%0000110000000000,D2
		BSR		TSTMSK
		BEQ		BRCMPI

		MOVE.L	#%0000000100000000,D2
		BSR		TSTMSK
		BEQ		BRBTST

		MOVE.L	#%0000101000000000,D2
		BSR		TSTMSK
		BEQ		BREORI

		MOVE.L	#%0000000000000000,D2
		BSR		TSTMSK
		BEQ		BRORI

		MOVE.L	#%0000010000000000,D2
		BSR		TSTMSK
		BEQ		BRSUBI
		
		BRA     BAD                 No mask matched, branch to BAD

INCREM  MOVE.L  (A0)+,D0            Post-Increment location to memory
        BSR     ASCII2HEX
        MOVE.L  D1,D0               Replace value with HEX value
        BRA     LOOP1               Loop back until ending location is reached
        
BAD     BRA     INCREM
BRSUBI	BRA		INCREM
BRORI   BRA		INCREM
BREORI	BRA		INCREM
BRBTST	BRA		INCREM
BRCMPI	BRA		INCREM
*BRMOVE	BRA		INCREM
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
        

*--------------------------
*  Instruction Subroutines
*--------------------------
BRRTS 
        * Call Print TAB function '      '
        *LEA     _RTS, A1       Load 'RTS' to be printed
        MOVE.B    #0, D0        Load the length of message
        BRA     INCREM          Return to subroutine

BRMOVE
        BSR     EXTMSK_CD       Get the size of MOVE instruction
        BSR     EXTMSK_9AB      Get the register
        BSR     EXTMSK_678      Get the OPmode
        BSR     EXTMSK_345      Get the EA mode
        BSR     EXTMSK_012      Get the EA Register
        * Call Print 'MOVE' function
        * Call Print Dot '.' function
        * Call Function that prints the Size (B/W/L)
        * Call Print TAB '   ' function
        LEA     MODE_TBL,A6     Load the EA_Table
        MOVE.B  MSK_345,D3      Load the EA MODE
        MOVE.B  MSK_345,MODE   
        MULU    #4,D3
        JSR     00(A6,D3)
        
        * Call Print COMMA function ','
        
        LEA     MODE_TBL,A6
        MOVE.B  MSK_678,D3      Load the OP Mode
        MOVE.B  MSK_678,MODE
        MULU    #4, D3
        JSR     00(A6,D3)
        
        BRA     INCREM

*----------------------------------------------
*   User Functions
*----------------------------------------------
EXTMSK_678      * 15 14 13 12 11 10 09[08 07 06]05 04 03 02 01 00
        MOVE.L  (A0),D0                 Transfer data to memory
        BSR     ASCII2HEX               Convert data to HEX
        MOVE.L  D1,D0                   Input
        MOVE.L  #%0000000111000000,D2   Mask
        BSR     EXTMSK                  Extract masked bits
        MOVE.B  D1,MSK_678              Store masked bits
        RTS                             Return to caller
        
EXTMSK_CD       * 15 14[13 12]11 10 09 08 07 06 05 04 03 02 01 00
        MOVE.L  (A0),D0
        BSR     ASCII2HEX
        MOVE.L  D1,D0
        MOVE.L  #%0011000000000000,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_CD
        RTS
        
EXTMSK_5        * 15 14 13 12 11 10 09 08 07[06]05 04 03 02 01 00
        MOVE.L  (A0),D0
        BSR     ASCII2HEX
        MOVE.L  D1,D0
        MOVE.L  #%0000000000100000,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_5
        RTS
        
EXTMSK_012      * 15 14 13 12 11 10 09 08 07 06 05 04 03[02 01 00]
        MOVE.L  (A0),D0
        BSR     ASCII2HEX
        MOVE.L  D1,D0
        MOVE.L  #%0000000000000111,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_012
        RTS
        
EXTMSK_345      * 15 14 13 12 11 10 09 08 07 06[05 04 03]02 01 00
        MOVE.L  (A0),D0
        BSR     ASCII2HEX
        MOVE.L  D1,D0
        MOVE.L  #%0000000000111000,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_345
        RTS
        
EXTMSK_9AB      * 15 14 13 12[11 10 09]08 07 06 05 04 03 02 01 00
        MOVE.L  (A0),D0
        BSR     ASCII2HEX
        MOVE.L  D1,D0
        MOVE.L  #%0000111000000000,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_9AB
        RTS

JMP_D0 
            *ummm we can do a couple of things here
            *we can add the print stuff directly in here
            *or we can make seperate print functions
        RTS
JMP_D1 
            *see JMP_D0
        RTS
JMP_D2 
            *see JMP_D0
        RTS
JMP_D3 
            *see JMP_D0
        RTS
JMP_D4 
            *see JMP_D0
        RTS
JMP_D5
            *see JMP_D0
        RTS
JMP_D6 
            *see JMP_D0
        RTS
JMP_D7 
            *see JMP_D0
        RTS
JMP_A0  
            *see JMP_D0
        RTS
JMP_A1 
            *see JMP_D0
        RTS
JMP_A2 
            *see JMP_D0
        RTS
JMP_A3
            *see JMP_D0
        RTS
JMP_A4 
            *see JMP_D0
        RTS
JMP_A5 
            *see JMP_D0
        RTS
JMP_A6 
            *see JMP_D0
        RTS
JMP_A7
            *see JMP_D0
        RTS
            
JMP_M0
        *Need to print a Data Register
        *Call function to go to the data register to be printed
        *Need to use reg table
        LEA     DN_TBL,A6 
        MOVE.B  MODE,D3     Load the mode
        MULU    #4,D3
        JSR     00(A6,D3)
        LEA     _M0,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
JMP_M1
        *Need to print a Address Register
        *Call function to go to the address register to be printed
        LEA     AN_TBL,A6
        MOVE.B  MODE,D3     Load the mode
        MULU    #4,D3
        JSR     00(A6,D3)
        LEA     _M1,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
JMP_M2
        LEA     _M2,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
JMP_M3
        *Call function to print a '(' paran
        LEA     AN_TBL,A6
        MOVE.B  MODE,D3     Load the mode
        MULU    #4,D3
        JSR     00(A6,D3)
        LEA     _M3,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
JMP_M4
        LEA     _M4,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
JMP_M5
        LEA     _M5,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
JMP_M6 
        LEA     _M6,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS
JMP_M7 
        *Call Print Pound Sign function
        *Retrieve value from Memory
        *Print value
        LEA     _M7,A1
        MOVE.B  #14, D0
        TRAP    #15
        RTS

*---------------------------
*   TABLES:
*   REGISTER:   (D0-D7 and A0-A7)
*   OPmodes:    (Modes 000-111)
*   EAmodes:    (Modes 000-111)
*   MANIP:      (...)    

*---------------------------
*   DN Table
*   0000-0111 = D0-D7
*   1000-1111 = A0-A7
*---------------------------

DN_TBL
        JMP     JMP_D0  000
        JMP     JMP_D1  001
        JMP     JMP_D2  010
        JMP     JMP_D3  011
        JMP     JMP_D4  100
        JMP     JMP_D5  101
        JMP     JMP_D6  110
        JMP     JMP_D7  111
            
*-----------------------------
*   MODE Table
*   MODES (0000-0111)
*-----------------------------
MODE_TBL
        JMP     JMP_M0  000
        JMP     JMP_M1  001
        JMP     JMP_M2  010
        JMP     JMP_M3  011
        JMP     JMP_M4  100
        JMP     JMP_M5  101
        JMP     JMP_M6  110
        JMP     JMP_M7  111
            
*-----------------------------
*   AN Table
*   MODES (0000-0111)
*-----------------------------
AN_TBL
        JMP     JMP_A0  000
        JMP     JMP_A1  001
        JMP     JMP_A2  010
        JMP     JMP_A3  011
        JMP     JMP_A4  100
        JMP     JMP_A5  101
        JMP     JMP_A6  110
        JMP     JMP_A7  111

        BRA     DONE
     
        END     START

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
BYTES   EQU     $8FFF   Number of bytes to read from file (max address - min address)
SLOC    DS.B    4       Starting location storage
ELOC    DS.B    4       Ending location storage
MSK_012 DS.B    1       Storage for bits 0,1,2
MSK_345 DS.B    1       Storage for bits 3,4,5
MSK_5   DS.B    1       Storage for bit 5
MSK_67  DS.B    1       Storage for bits 6,7
MSK_8   DS.B    1       Storage for bit 8
MSK_678 DS.B    1       Storage for bits 6,7,8
MSK_89AB DS.B   1       Storage for bits 8,9,10,11
MSK_9AB DS.B    1       Storage for bits 9,10,11
MSK_CD  DS.B    1       Storage for bits 12,13
MODE    DS.B    1       Storage for which bits to use EA or OP
DISP8   DS.B    1       Storage for 8bits displacement
DISP16  DS.B    2       Storage for 16bits displacement (Word)
DISP32  DS.B    4       Storage for 32bits displacement (Long)

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
ERR3    DC.B    'That file does not exist. Please make sure it is located in the same directory,',CR,LF
        DC.B    'and try again.',CR,LF,0
FILE    DC.B    'test.s68',0

        ORG     OADDR

START
        JMP     DEBUG           Debug shortcut for dev team
        LEA     MSSG0,A1        Welcome message
        MOVE.B  #14,D0
        TRAP    #15
        
        BRA     PRMPT0
        
DEBUG   MOVE.L  #$7000,(SLOC)   Store starting location
        MOVE.L  #$701F,(ELOC)   Store ending location
        LEA     FILE,A1         Set file
        MOVE    #51,D0          Open file
        TRAP    #15
        
        LEA     MNADDR,A1       Read file data from starting location
        MOVE.L  #BYTES,D2       Set bytes to read
        MOVE    #53,D0          Read from file
        TRAP    #15
        
        BRA     CMPRSS          Manipulate data, then go to OP

*-----------------------------------
*    Conversion & Comparison Methods
*-----------------------------------
        
*
* Compress: Convert (and effectively, compress) data stored through TRAP to meaningful HEX data in the memory
*

CMPRSS  MOVEA.L #$7050,A0       Load address register past file header
                                * ^ TODO?: (could save some cycles by setting it to (SLOC - MNADDR) * 2 + MNADDR)
        MOVEA.L #MNADDR,A1      Set write location to minimum address
        
CMPADV  CMP.L   ELOC,A1         Compare ending location to write location
                                * ^ (saves cycles by only manipulating necessary data instead of comparing to MXADDR)
        BGE     OP              Branch to OP if <= to location
        MOVE.L  (A0)+,D1        Transfer data to memory, post-increment location
        BSR     TSTGRBG         Test if the data is not important (Easy68K specific data)
        BEQ     CMPADV          If z-flag is set, then we don't care about that memory
        
        MOVE.L  D1,D0           Move data to D0
        BSR     ASCII2HEX       Convert to HEX
        MOVE.W  D1,(A1)         Move HEX to A1
        ADD.W   #$2,A1          Advance A1 to next byte
        BRA     CMPADV          Loop back
        
TSTGRBG * CMPRSS helper: Test if data is useful
        MOVE.L  D1,-(SP)        Push D1 on stack
        CMP.W   #$0D0A,D1
        BEQ     FLAGST          
        ROL.L   #8,D1
        CMP.B   #$53,D1
        BEQ     FLAGST
        BRA     FLAGCL
        
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
        CMP.B   #$16,D1         16 = F
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
* Input value from D0, input mask from D2, output masked value to D1
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
* Input value from D0, input mask from D2, output value in D1
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

ILL4    LEA     ERR3,A1         File does not exist
        MOVE.B  #14,D0
        TRAP    #15

PRMPT0  LEA     MSSG3,A1        File name request message
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     FILE,A1         Set FILE as storage for string
        
        MOVE.B  #255,D1         Max bytes for file name
                
        MOVE.B  #2,D0           Input file name
        TRAP    #15

        MOVE    #51,D0          Open file
        TRAP    #15
        
        CMP.L   #$FFFFFFFF,D1   Test if the file was opened successfully
        BEQ     ILL4
        
        LEA     MNADDR,A1       Read file data from starting location
        MOVE    #BYTES,D2       Set bytes to read (max)
        MOVE    #53,D0          Read from file
        TRAP    #15
        
        * TODO: Move read operations to the end of user location input operations to set BYTES accordingly
        * OR, use the max bytes, scan for the end of the file, and add an extra error check to see if the ending address > than what exists
        
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
        
        BRA     CMPRSS
        
DONE    MOVE.B  #9,D0
        TRAP    #15

*--------------------
*   OP
*--------------------

OP      MOVEA.L SLOC,A0         Load address register

INCREM  CMP.L   ELOC,A0         Compare ending location to location
        BGE     DONE            Branch to DONE if <= to location
        MOVE.W  (A0)+,D0        Transfer data to memory, post-increment A0
        * Mask bits to determine OP-code and branch correspondingly-- high order bits are checked first
        
        MOVE.W  #%1110000010001000,D2
        BSR     TSTMSK
        BEQ     BRLSR

        MOVE.W  #%1110000001001000,D2
        BSR     TSTMSK
        BEQ     BRLSR

        MOVE.W  #%1110000000001000,D2
        BSR     TSTMSK
        BEQ     BRLSR

        MOVE.W  #%1110000010000000,D2
        BSR     TSTMSK
        BEQ     BRASL

        MOVE.W  #%1110000001000000,D2
        BSR     TSTMSK
        BEQ     BRASL

        MOVE.W  #%1110000000000000,D2
        BSR     TSTMSK
        BEQ     BRASL

        MOVE.W  #%1101000111000000,D2
        BSR     TSTMSK
        BEQ     BRADDA

        MOVE.W  #%1101000011000000,D2
        BSR     TSTMSK
        BEQ     BRADDA

        MOVE.W  #%1101000110000000,D2
        BSR     TSTMSK
        BEQ     BRADD

        MOVE.W  #%1101000101000000,D2
        BSR     TSTMSK
        BEQ     BRADD

        MOVE.W  #%1101000100000000,D2
        BSR     TSTMSK
        BEQ     BRADD

        MOVE.W  #%1101000010000000,D2
        BSR     TSTMSK
        BEQ     BRADD

        MOVE.W  #%1101000001000000,D2
        BSR     TSTMSK
        BEQ     BRADD

        MOVE.W  #%1101000000000000,D2
        BSR     TSTMSK
        BEQ     BRADD

        MOVE.W  #%1100000110000000,D2
        BSR     TSTMSK
        BEQ     BRAND

        MOVE.W  #%1100000101000000,D2
        BSR     TSTMSK
        BEQ     BRAND

        MOVE.W  #%1100000100000000,D2
        BSR     TSTMSK
        BEQ     BRAND

        MOVE.W  #%1100000010000000,D2
        BSR     TSTMSK
        BEQ     BRAND

        MOVE.W  #%1100000001000000,D2
        BSR     TSTMSK
        BEQ     BRAND

        MOVE.W  #%1100000000000000,D2
        BSR     TSTMSK
        BEQ     BRAND

        MOVE.W  #%1100000011000000,D2
        BSR     TSTMSK
        BEQ     BRMULU

        MOVE.W  #%1011000111000000,D2
        BSR     TSTMSK
        BEQ     BRCMPA

        MOVE.W  #%1011000011000000,D2
        BSR     TSTMSK
        BEQ     BRCMPA

        MOVE.W  #%1011000010000000,D2
        BSR     TSTMSK
        BEQ     BRCMP

        MOVE.W  #%1011000001000000,D2
        BSR     TSTMSK
        BEQ     BRCMP

        MOVE.W  #%1011000000000000,D2
        BSR     TSTMSK
        BEQ     BRCMP

        MOVE.W  #%1011000110000000,D2
        BSR     TSTMSK
        BEQ     BREOR

        MOVE.W  #%1011000101000000,D2
        BSR     TSTMSK
        BEQ     BREOR

        MOVE.W  #%1011000100000000,D2
        BSR     TSTMSK
        BEQ     BREOR

        MOVE.W  #%1001000111000000,D2
        BSR     TSTMSK
        BEQ     BRSUBA

        MOVE.W  #%1001000011000000,D2
        BSR     TSTMSK
        BEQ     BRSUBA

        MOVE.W  #%1001000110000000,D2
        BSR     TSTMSK
        BEQ     BRSUB

        MOVE.W  #%1001000101000000,D2
        BSR     TSTMSK
        BEQ     BRSUB

        MOVE.W  #%1001000100000000,D2
        BSR     TSTMSK
        BEQ     BRSUB

        MOVE.W  #%1001000010000000,D2
        BSR     TSTMSK
        BEQ     BRSUB

        MOVE.W  #%1001000001000000,D2
        BSR     TSTMSK
        BEQ     BRSUB

        MOVE.W  #%1001000000000000,D2
        BSR     TSTMSK
        BEQ     BRSUB

        MOVE.W  #%1000000000000000,D2
        BSR     TSTMSK
        BEQ     BRDIVS

        MOVE.W  #%0110000000000000,D2
        BSR     TSTMSK
        BEQ     BRBCC

        MOVE.W  #%0101000000000000,D2
        BSR     TSTMSK
        BEQ     BRADDQ

        MOVE.W  #%0100111001000000,D2
        BSR     TSTMSK
        BEQ     BRRTS

        MOVE.W  #%0100111010000000,D2
        BSR     TSTMSK
        BEQ     BRJSR

        MOVE.W  #%0100110100000000,D2
        BSR     TSTMSK
        BEQ     BRNOT

        MOVE.W  #%0100110010000000,D2
        BSR     TSTMSK
        BEQ     BRNOT

        MOVE.W  #%0100110000000000,D2
        BSR     TSTMSK
        BEQ     BRNOT

        MOVE.W  #%0100000111000000,D2
        BSR     TSTMSK
        BEQ     BRLEA

        MOVE.W  #%0100110011000000,D2
        BSR     TSTMSK
        BEQ     BRMOVEM

        MOVE.W  #%0100110010000000,D2
        BSR     TSTMSK
        BEQ     BRMOVEM

        MOVE.W  #%0100100011000000,D2
        BSR     TSTMSK
        BEQ     BRMOVEM

        MOVE.W  #%0100100010000000,D2
        BSR     TSTMSK
        BEQ     BRMOVEM

        MOVE.W  #%0011000001000000,D2
        BSR     TSTMSK
        BEQ     BRMOVEA

        MOVE.W  #%0011000000000000,D2
        BSR     TSTMSK
        BEQ     BRMOVE

        MOVE.W  #%0010000000000000,D2
        BSR     TSTMSK
        BEQ     BRMOVE

        MOVE.W  #%0010000000010000,D2
        BSR     TSTMSK
        BEQ     BRMOVEA

        MOVE.W  #%0001000000000000,D2
        BSR     TSTMSK
        BEQ     BRMOVE

        MOVE.W  #%0000110000000000,D2
        BSR     TSTMSK
        BEQ     BRCMPI

        MOVE.W  #%0000000100000000,D2
        BSR     TSTMSK
        BEQ     BRBTST

        MOVE.W  #%0000101000000000,D2
        BSR     TSTMSK
        BEQ     BREORI

        MOVE.W  #%0000000000000000,D2
        BSR     TSTMSK
        BEQ     BRORI

        MOVE.W  #%0000010000000000,D2
        BSR     TSTMSK
        BEQ     BRSUBI
     
        BRA     BAD                 No mask matched, branch to BAD
        
BAD     BRA     INCREM
BRMOVEM BRA     INCREM


*--------------------------
*  Instruction Subroutines
*--------------------------
BRADD
        BSR     EXTMSK_Bto0
        *Print ADD
        *Print  .
        *Print  size according to OPMODE
        *Print  tab
        MOVE.B  MSK_678, D5 Copy OPmode
        CMP.B   #$4, D5 If greater than 4, Syntax is ADD Dn, <ea>
        BGT     BRADD1
        BSR     EAMODE
        *Print ','
        MOVE.B  MSK_9AB,MODE      Get the register number
        BSR     DNMODE
        BRA     INCREM
BRADD1                
        MOVE.B  MSK_9AB,MODE      Get the register number
        BSR     DNMODE
        *Print '','
        BSR     EAMODE        
        BRA     INCREM

BRADDA
        *Print ADDA
        *Print  .
        *Print  Size according to OPMODE
        *Print  tab
        BSR     EAMODE 
        *Print  ','
        MOVE.B  MSK_9AB,MODE      Get the register number
        BSR     DNMODE       
        BRA     INCREM
BRADDQ
        BSR     EXTMSK_9AB
        BSR     EXTMSK_7to0
        *Print ADDQ
        *Print  .
        *Print  size according to MSK_67
        *Print  tab
        *Print  #
        *Print  Data
        *Print  ,
        BSR     EAMODE
        BRA     INCREM
BRAND   
        BSR     EXTMSK_Bto0      
        *PRINT AND
        *Print DOT '.'
        *Print Size
        *Print Tab
        MOVE.B  MSK_678, D5 Copy OPmode
        CMP.B   #$4, D5 If greater than 4, Syntax is AND Dn, <ea>
        BGT     ANDMODE1
        BSR     EAMODE
        *Call function to print a COMMA ','
        MOVE.B  MSK_9AB,MODE Copy the EA<register> into MODE
        BSR     DNMODE
        BRA     INCREM Jump to next instruction
ANDMODE1 *AND Dn, <ea>
        MOVE.B  MSK_9AB,MODE Copy the EA<register> into MODE
        BSR     DNMODE
        *Call function to print a COMMA ','
        BSR     EAMODE
        BRA     INCREM  Jump to next instruction

BRBTST
        BSR     EXTMSK_Bto0
        *Print  BTST
        *Print  tab
        MOVE.B  MSK_678,D4
        CMP.B   #4,D4 if 4 then it's Dn,<ea>
        BNE     BTSTIMMED 
        MOVE.B  MSK_9AB,MODE
        BSR     DNMODE
        *Print comma ','
        BSR     EAMODE
        BRA     INCREM
BTSTIMMED        
        *Still need to figure out and finish coding
        BRA     INCREM

BRBCC   
        BSR     EXTMSK_89AB
        *Print  TAB
        MOVE.B  MSK_89AB,D4
        BSR     EXTMSK_70 Get lower 8 bits(displacement)
        MOVE.B  DISP8,D4
        CMP.B   #7,D4
        BEQ     BRBEQ
        CMP.B   #13,D4
        BEQ     BRBLT
        CMP.B   #6,D4
        BEQ     BRBNE
        CMP.B   #2,D4
        BEQ     BRBHI
BRBEQ
        *Print BEQ
        *CMP DISP8 to get displacement
        *If 00 then 16 displacement
        *If FF then 32 displacement
        BRA     ENDBCC        
BRBLT   
        *Print BLT
        *CMP DISP8 to get displacement
        *If 00 then 16 displacement
        *If FF then 32 displacement
        BRA     ENDBCC
BRBNE   
        *Print BNE
        *CMP DISP8 to get displacement
        *If 00 then 16 displacement
        *If FF then 32 displacement
        BRA     ENDBCC
BRBHI
        *Print BHI
        *CMP DISP8 to get displacement
        *If 00 then 16 displacement
        *If FF then 32 displacement
ENDBCC  
        BRA     INCREM
BRCMP
        BSR     EXTMSK_Bto0
        *Print  CMP
        *Print  .
        *Print  size according to opmode
        *Print  tab
        BSR     EAMODE
        *Print  ,
        MOVE.B  MSK_9AB,MODE Copy the EA<register> into MODE
        BSR     DNMODE
        BRA     INCREM Jump to next instruction       
BRCMPA
        BSR     EXTMSK_Bto0
        *Print  CMPA
        *Print  .
        *Print  size according to opmode
        *Print  tab
        BSR     EAMODE
        *Print  ,
        MOVE.B  MSK_9AB,MODE Copy the EA<register> into MODE
        BSR     ANMODE
        BRA     INCREM Jump to next instruction   
BRCMPI
        BSR     EXTMSK_7to0
        *Print  CMPI
        *Print  .
        *Print  size according to bits 67
        *Print  tab
        *Print  #
        *Print  data from memory
        *Print  ','
        BSR     EAMODE
        BRA     INCREM
BRRTS 
        * Call Print TAB function '      '
        *LEA     _RTS, A1       Load 'RTS' to be printed
        MOVE.B    #0, D0        Load the length of message
        BRA     INCREM          Return to subroutine
BRLEA
        BSR     EXTMSK_Bto0
        *Print  LEA
        *Print  tab
        BSR     EAMODE
        *Print  ,
        MOVE.B  MSK_9AB,MODE Copy the EA<register> into MODE
        BSR     ANMODE        

BRJSR
        BSR     EXTMSK_012
        BSR     EXTMSK_345
        *Print  JSR
        *Print  tab
        BSR     EAMODE
        BRA     INCREM
BRMOVE
        BSR     EXTMSK_CD       Get the size of MOVE instruction
        BSR     EXTMSK_Bto0
        * Call Print 'MOVE' function
        * Call Print Dot '.' function
        * Call Function that prints the Size (B/W/L)
        * Call Print TAB '   ' function
        BSR     EAMODE
        * Call Print COMMA function ','
        LEA     MODE_TBL,A6     Load the Mode table
        MOVE.B  MSK_678,D3      Load the OP Mode
        MOVE.B  MSK_9AB,MODE    Copy the EA mode into the mode variable
        MULU    #4, D3          
        JSR     00(A6,D3)       Jump to appropriate EA<mode> 
        CLR.L   D3       
        BRA     INCREM          Go to next instruction

BRMOVEA 
        BSR     EXTMSK_CD       Get the size of MOVE instruction
        BSR     EXTMSK_Bto0
        *Call Print 'MOVEA' function
        *Call Print DOT '.' function
        *Call function that prints the size (B/W/L)
        *Call Print TAB '   ' function
        BSR     EAMODE
        *Call print COMMA function ','
        MOVE.B  MSK_9AB,MODE      Get the register number
        BSR     ANMODE
        BRA     INCREM          Get next instruction
BRASL
        *Print ASL
        *Print  tab
        BSR     EXTMSK_67
        MOVE.B  MSK_67, D4
        CMP.B   #3,D4  If 3 or 11 then it's a memory shift
        BEQ     ASLMEMORY
        *Not a memory shift its a Register Shift
        BSR     EXTMSK_9AB
        BSR     EXTMSK_5
        BSR     EXTMSK_012
        BSR     EXTMSK_8   Should alway be 1 because ASL not ASR
        MOVE.B  MSK_5, D4
        CMP.B   #1, D4 If 1 it's Dn,Dn
        BEQ     ASLDN
        *#data,Dn
        *Print  #
        *Print bits 9AB, 000 is 8
        BRA     ASLDNPRINT
ASLDN   *Dn, Dn
        MOVE.B  MSK_9AB,MODE
        BSR     DNMODE     
ASLDNPRINT
        *Print ,
        MOVE.B  MSK_012, MODE
        BSR     DNMODE
        BRA     INCREM        
ASLMEMORY
        BSR     EXTMSK_012
        BSR     EXTMSK_345
        BSR     EAMODE
        BRA     INCREM

        BRA     INCREM
BRLSR
        *Print LSR
        *Print  tab
        BSR     EXTMSK_67
        MOVE.B  MSK_67, D4
        CMP.B   #3,D4  If 3 or 11 then it's a memory shift
        BEQ     LSRMEMORY
        *Not a memory shift its a Register Shift
        BSR     EXTMSK_9AB
        BSR     EXTMSK_5
        BSR     EXTMSK_012
        BSR     EXTMSK_8   Should alway be 0 because LSR not LSL
        MOVE.B  MSK_5, D4
        CMP.B   #1, D4 If 1 it's Dn,Dn
        BEQ     LSRDN
        *#data,Dn
        *Print  #
        *Print bits 9AB 000 is 8
        BRA     LSRDNPRINT
LSRDN   *Dn, Dn
        MOVE.B  MSK_9AB,MODE
        BSR     DNMODE     
LSRDNPRINT
        *Print ,
        MOVE.B  MSK_012, MODE
        BSR     DNMODE
        BRA     INCREM        
LSRMEMORY
        BSR     EXTMSK_012
        BSR     EXTMSK_345
        BSR     EAMODE
        BRA     INCREM

BRMULU
        BSR     EXTMSK_Bto0
        *Print  MULU
        *Print  tab
        BSR     EAMODE
        *Print  ,
        MOVE.B  MSK_9AB,MODE      Get the register number
        BSR     DNMODE
        BRA     INCREM
BRDIVS
        BSR     EXTMSK_Bto0
        *Print  DIVS
        *Print  tab
        BSR     EAMODE
        *Print  ,
        MOVE.B  MSK_9AB,MODE      Get the register number
        BSR     DNMODE        
        BRA     INCREM
BREOR
        BSR     EXTMSK_Bto0
        *Print EOR
        *Print a tab
        MOVE.B  MSK_9AB, MODE     Copy the register Number
        BSR     DNMODE
        *Print a comma ','
        BSR     EAMODE
        BRA     INCREM          Get next instruction
BRORI
        BSR     EXTMSK_7to0
        *Print  ORI
        *Print  tab
        *Print  #
        *Print  data according to size
        *Print  comma ','
        BSR     EAMODE
        BRA     INCREM
BREORI
        BSR     EXTMSK_7to0
        *Print  EORI
        *Print  tab
        *Print  #
        *Print  data according to size
        *Print  comma ','
        BSR     EAMODE
        BRA     INCREM
BRNOT
        BSR     EXTMSK_7to0
        *Print NOT
        *Call function to print DOT '.'
        *Call function to print based on size (B/W/L)
        *Call function to print a TAB
        BSR     EAMODE
        BRA     INCREM
BRSUB
        BSR     EXTMSK_Bto0
        MOVE.B  MSK_678, D5 Copy OPmode
        *Print SUB
        *Print .
        *Print Size according to EXTMSK_678
        CMP.B   #$4, D5 If greater than 4, Syntax is SUB Dn,<ea>
        BGT     BRSUB1
        *Syntax SUB <ea>,Dn
        BSR     EAMODE
        *Print ','
        MOVE.B  MSK_9AB,MODE Load the register number
        BSR     DNMODE
        BRA     INCREM             
BRSUB1    
        MOVE.B  MSK_9AB,MODE Load the register number
        BSR     DNMODE      
        *Print comma ','
        BSR     EAMODE
        BRA     INCREM      Get next instruction
BRSUBA
        BSR     EXTMSK_Bto0
        *Print  SUBA
        *Print  .
        *Print  Size according to MSK_678
        *Print  tab
        BSR     EAMODE  Print <EA>
        *Print  ,
        MOVE.B  MSK_9AB,MODE Load the register number
        BSR     ANMODE  Print <An>     
        BRA     INCREM
BRSUBI
        BSR     EXTMSK_7to0
        *Print  SUBI
        *Print  .
        *Print  size according to bits 67
        *Print  tab
        *print  #
        *print  data *32/16/8
        *print  ','
        BSR     EAMODE
        BRA     INCREM

*----------------------------------------------
*   User Functions
*----------------------------------------------
DNMODE  
        LEA     DN_TBL,A6  Load Dn table
        MOVE.B  MODE,D3 Load the register number
        MULU    #4,D3
        JSR     00(A6,D3)  Jump to appropriate Dn  
        CLR.L   D3
        RTS
ANMODE
        LEA     AN_TBL,A6       Load the address table
        MOVE.B  MODE, D3        Move register into MODE variabl
        MULU    #4,D3 
        JSR     00(A6,D3)       Jump to appropriate An
        CLR.L   D3 
        RTS
EAMODE
        LEA     MODE_TBL,A6 Load the mode table
        MOVE.B  MSK_345,D3 load the EA<mode>
        MULU    #4,D3       Get offset address
        MOVE.B  MSK_012,MODE Move EA<register>
        JSR     00(A6,D3)   Jump to appropriate MODE
        CLR.L   D3
        RTS
EXTMSK_Bto0     * 15 14 13 12 [11 10 09 08 07 06 05 04 03 02 01 00]
        BSR     EXTMSK_9AB Get register
        BSR     EXTMSK_678 Get OPmode
        BSR     EXTMSK_345 Get EA<mode>
        BSR     EXTMSK_012 Get EA<register>
        RTS
EXTMSK_7to0     * 15 14 13 12 11 10 09 08 [07 06 05 04 03 02 01 00]
        BSR     EXTMSK_67
        BSR     EXTMSK_345 Get EA<mode>
        BSR     EXTMSK_012 Get EA<register>
        RTS
EXTMSK_70     * 15 14 13 12 11 10 09 08 [07 06 05 04 03 02 01 00]
        MOVE.L  (A0),D0                 Transfer data to memory
        BSR     ASCII2HEX               Convert data to HEX
        MOVE.L  D1,D0                   Input
        MOVE.L  #%0000000111111111,D2   Mask
        BSR     EXTMSK                  Extract masked bits
        MOVE.B  D1,DISP8                Store masked bits
        RTS
EXTMSK_678      * 15 14 13 12 11 10 09[08 07 06]05 04 03 02 01 00
        MOVE.L  (A0),D0                 Transfer data to memory
        BSR     ASCII2HEX               Convert data to HEX
        MOVE.L  D1,D0                   Input
        MOVE.L  #%0000000111000000,D2   Mask
        BSR     EXTMSK                  Extract masked bits
        MOVE.B  D1,MSK_678              Store masked bits
        RTS                             Return to caller
        
EXTMSK_89AB     * 15 14 13 12 [11 10 09 08] 07 06 05 04 03 02 01 00
        MOVE.L  (A0),D0                 Transfer data to memory
        BSR     ASCII2HEX               Convert data to HEX
        MOVE.L  D1,D0                   Input
        MOVE.L  #%0000111100000000,D2   Mask
        BSR     EXTMSK                  Extract masked bits
        MOVE.B  D1,MSK_89AB              Store masked bits
        RTS                             Return to caller
        
EXTMSK_67      * 15 14 13 12 11 10 09 08 [07 06]05 04 03 02 01 00
        MOVE.L  (A0),D0                 Transfer data to memory
        BSR     ASCII2HEX               Convert data to HEX
        MOVE.L  D1,D0                   Input
        MOVE.L  #%0000000011000000,D2   Mask
        BSR     EXTMSK                  Extract masked bits
        MOVE.B  D1,MSK_67               Store masked bits
        RTS                             Return to caller

EXTMSK_CD       * 15 14[13 12]11 10 09 08 07 06 05 04 03 02 01 00
        MOVE.L  (A0),D0
        BSR     ASCII2HEX
        MOVE.L  D1,D0
        MOVE.L  #%0011000000000000,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_CD
        RTS
        
EXTMSK_5        * 15 14 13 12 11 10 09 08 07 06[05]04 03 02 01 00
        MOVE.L  (A0),D0
        BSR     ASCII2HEX
        MOVE.L  D1,D0
        MOVE.L  #%0000000000100000,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_5
        RTS
EXTMSK_8        * 15 14 13 12 11 10 09 [08] 07 06 05 04 03 02 01 00
        MOVE.L  (A0),D0
        BSR     ASCII2HEX
        MOVE.L  D1,D0
        MOVE.L  #%0000000100000000,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_8
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


*----------------------------------------------------------------------------
* Title      : 3B Disassembler
* Written by : The Three Bears: Joseph Schooley, Nguyen Tong, Terence Calhoun
* Date       : 11/11/2013
* Description: A Motorola MC68000 Microprocessor Disassembler 
*----------------------------------------------------------------------------
CR      EQU     $0D     ASCII: carriage return
LF      EQU     $0A     ASCII: line feed
TB      EQU     $09     ASCII: horizontal tab
DOT     EQU     $2E     ASCII: .
COMMA   EQU     $2C     ASCII: ,
PLUS    EQU     $2B     ASCII: +
MINUS   EQU     $2D     ASCII: -
OPARE   EQU     $28     ASCII: (
CPARE   EQU     $29     ASCII: )
SPACE   EQU     $20     ASCII: Space
SHARP   EQU     $23     ASCII: #
DOLLAR  EQU     $24     ASCII: $
PERCEN  EQU     $25     ASCII: %

OADDR   EQU     $1000   Org address
MNADDR  EQU     $7000   Min address
MXADDR  EQU     $FFFFF0 Max address
BYTES   EQU     $8FFF   Number of bytes to read from file (max address - min address)
GBUFF   DS.L    1       Pointer to next location in "Good buffer"
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

*-----I/O Memory-----
IOOPCD  DS.B    1       IO offset value for OP-code in OP-code name memory
IOADDR  DS.L    1       IO address value for instruction memory location
IOOPRA  DS.L    1       IO operand value for instruction EA
LC      DS.B    1       IO line counter for screen

* OP-code name memory
* Example to display MULU:
*       LEA     OPCDNM,A1
*       ADD.L   #$2B,A1
*       MOVE.B  #14,D0
*       TRAP    #15
*                NAME           DEC     HEX
OPCDNM  DC.B    'MOVE',0        00      00
        DC.B    'MOVEA',0       05      05
        DC.B    'MOVEM',0       11      0B
        DC.B    'ADD',0         17      11
        DC.B    'ADDA',0        21      15
        DC.B    'ADDQ',0        26      1A
        DC.B    'SUB',0         31      1F
        DC.B    'SUBA',0        35      23
        DC.B    'SUBI',0        40      28
        DC.B    'MULU',0        45      2D
        DC.B    'DIVS',0        50      32
        DC.B    'LEA',0         55      37
        DC.B    'AND',0         59      3B
        DC.B    'ORI',0         63      3F
        DC.B    'EOR',0         67      43
        DC.B    'EORI',0        71      47
        DC.B    'NOT',0         76      4C
        DC.B    'ASL',0         80      50
        DC.B    'LSR',0         84      54
        DC.B    'BTST',0        88      58
        DC.B    'CMP',0         93      5D
        DC.B    'CMPA',0        97      61
        DC.B    'CMPI',0        102     66
        DC.B    'BCC',0         107     6B
        DC.B    'BEQ',0         111     6F
        DC.B    'BLT',0         115     73
        DC.B    'BNE',0         119     77
        DC.B    'BHI',0         123     7B
        DC.B    'JSR',0         127     7F
        DC.B    'RTS',0         131     83
        DC.B    'BAD',0         135     87


MSSG0   DC.B    '  _     _     _     _     _     _ ',CR,LF
        DC.B    ' (o\---/o)   (o\---/o)   (o\---/o)',CR,LF
        DC.B    '  | - - |     | ^ ^ |     | . . |',CR,LF
        DC.B    ' _( (Y)_)_,--.(_(Y)_),--._(_(Y) )_',CR,LF
        DC.B    '/ /___|_  ".."       ".."  _|___\ \',CR,LF
        DC.B    '\_______):     THREE     :(_______/',CR,LF
        DC.B    '| |   |        BEARS        |   | |',CR,LF
        DC.B    '| |   |    DISASSEMBLER     |   | |',CR,LF
        DC.B    '|  \__|__Joey__Terence__Win_|__/  |',CR,LF
        DC.B    ' \    I  /_  )   |   (  _\  I    /',CR,LF
        DC.B    '  \____)___)(___/ \___)(___(____/',CR,LF
        DC.B    'Welcome to 3B Disassembler. Enter 0 at any time to quit.',CR,LF,0
MSSG1   DC.B    'Enter the starting location of the code to be disassembled:',0
MSSG2   DC.B    'Enter the ending location of the code to be disassembled:',0
MSSG3   DC.B    'Enter the name of the file you wish to disassemble:',0
MSSG4   DC.B    'Press any key for the next page.',0
MSSG5   DC.B    'You have reached the end of the program.',0
HEADR   DC.B    'Address      Code        Line',CR,LF,0
ERR0    DC.B    'The input address was too small.',CR,LF,0
ERR1    DC.B    'The input address was too big.',CR,LF,0
ERR3    DC.B    'That file does not exist. Please make sure it is located in the same directory,',CR,LF
        DC.B    'and try again.',CR,LF,0
FILE    DC.B    'test.s68',0

        ORG     OADDR

START   MOVE.B  #0,LC
        JMP     DEBUG           Debug shortcut for dev team
        LEA     MSSG0,A1        Welcome message
        MOVE.B  #14,D0
        TRAP    #15
        
        BRA     PRMPT0
        
DEBUG   MOVE.L  #$7000,(SLOC)   Store starting location
        MOVE.L  #$7000,(GBUFF)  Store good buffer
        MOVE.L  #$7100,(ELOC)   Store ending location
        LEA     FILE,A1         Set file
        MOVE    #51,D0          Open file
        TRAP    #15
        
        LEA     MNADDR,A1       Read file data from starting location
        MOVE.L  #BYTES,D2       Set bytes to read
        MOVE    #53,D0          Read from file
        TRAP    #15
        
        BSR     CMPRSS          Manipulate data

        LEA     HEADR,A1
        MOVE.B  #14,D0
        TRAP    #15

        BRA     OP

*-----------------------------------
*    Conversion & Comparison Methods
*-----------------------------------

*
* Return: Helper method for lazy programmers
*

RETURN  RTS

*
* Compress: Convert (and effectively, compress) data stored through TRAP to meaningful HEX data in the memory
*

CMPRSS  MOVEA.L #$7050,A0       Load address register past file header
                                * ^ TODO?: (could save some cycles by setting it to (SLOC - MNADDR) * 2 + MNADDR)
        MOVEA.L #MNADDR,A1      Set write location to minimum address
        
CMPADV  CMP.L   ELOC,A1         Compare ending location to write location
                                * ^ (saves cycles by only manipulating necessary data instead of comparing to MXADDR)
        BGE     RETURN          Branch to OP if <= to location
        MOVE.L  (A0)+,D1        Transfer data to memory, post-increment location
        CMP.W   #$0D0A,D1       Test if the data is not important (Easy68K specific data)
        BEQ     CMPGRBG         If z-flag is set, then we don't care about that memory
        
        MOVE.L  D1,D0           Move data to D0
        BSR     ASCII2HEX       Convert to HEX
        MOVE.W  D1,(A1)         Move HEX to A1
        ADD.W   #$2,A1          Advance A1 to next byte
        BRA     CMPADV          Loop back
        
CMPGRBG * CMPRSS helper: If the data was garbage, advance to next useful data
        ADD.L   #8,A0
        BRA     CMPADV
        
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
                
                              * XAXBXCXD
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
* HEX2ASCII: Convert ASCII into HEX.
* Input HEX from D0.W output ASCII to D1.L
*

HEX2ASCII
        MOVE.L  D0,D1           Move the input to D1

                              * XXXXABCD
        SWAP	D1	        	ABCDXXXX
        CLR.W	D1		        ABCD0000
        ROL.L	#4,D1   		BCD0000A
        LSL.B	#4,D1	    	BCD000A0
        ROL.W	#8,D1		    BCD0A000
        ROL.L	#4,D1   		CD0A000B
        ROL.W	#8,D1	    	CD0A0B00
        ROL.L	#4,D1		    D0A0B00C
        LSL.B	#4,D1		    D0A0B0C0
        ROL.L	#4,D1		    0A0B0C0D

        MOVE.L  D2,-(SP)        Push D2 on stack
        CLR.L   D2              
        MOVE.B  #3,D2           Set rotation count
        BSR     H2A             Start loop
        MOVE.L  (SP)+,D2        Restore D2

        ADD     #$3030,D1       Convert last word
        SWAP    D1              Swap bytes
        ADD     #$3030,D1       Convert first word
        SWAP    D1              Restore order
        RTS                     Return to caller
        
        
H2A   * ASCII2HEX helper: Convert bytes that were > 30 to appropriate HEX value
        CMP.B   #$A,D1         A = 11
        BEQ     H2AA
        CMP.B   #$B,D1         B = 12
        BEQ     H2AB
        CMP.B   #$C,D1         C = 13
        BEQ     H2AC
        CMP.B   #$D,D1         D = 14
        BEQ     H2AD
        CMP.B   #$E,D1         E = 15
        BEQ     H2AE
        CMP.B   #$F,D1         F = 16
        BEQ     H2AF
        
H2AADV  * H2A conversion branch helper: Rotate to the next byte, and loop back to H2A until all bytes have been analyzed/converted
        ROL.L   #8,D1           Rotate 1st byte to the end
        DBRA    D2,H2A          If count is > 0, decrement and loop back to A2H
        RTS                     If count == 0, return to sub-routine

* H2A conversion branches
H2AA    MOVE.B  #$11,D1
        BRA     H2AADV
H2AB    MOVE.B  #$12,D1
        BRA     H2AADV
H2AC    MOVE.B  #$13,D1
        BRA     H2AADV
H2AD    MOVE.B  #$14,D1
        BRA     H2AADV
H2AE    MOVE.B  #$15,D1
        BRA     H2AADV
H2AF    MOVE.B  #$16,D1
        BRA     H2AADV


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
        
*
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

*
* Display ASCII: Display the ASCII from D0.L to screen
*
DSPAX   MOVEM.L D0-D2,-(SP)     Push D0-D2
        MOVE.L  D0,D1
        BRA     DSPHST          Branch to DISPHX Start

*
* Display HEX Word: Display the hex from D0.W to screen
*

DSPHXW  MOVEM.L D0-D2,-(SP)     Push D0-D2 on stack
        BSR     HEX2ASCII       Get ASCII in D1

DSPHST  CLR.L   D2              
        MOVE.B  #3,D2           Set rotation count
        MOVE.B  #6,D0           Set trap #6 to read single char from D1.B
        BSR     DSPHADV         Start loop

        MOVEM.L  (SP)+,D0-D2    Restore D0-D2
        RTS                     Return to caller

DSPHADV ROL.L   #8,D1           Rotate bytes left
        TRAP    #15             Display char in D1.B
        DBRA    D2,DSPHADV      If count is > 0, decrement and loop back to DSPHADV
        RTS                     If count == 0, return to sub-routine

*
* Display HEX Long: Display the hex from D0.L to screen
*

DSPHXL  SWAP    D0              Swap first half to D0.W
        BSR     DSPHXW          Display first half
        SWAP    D0              Swap lower half to D0.W
        BSR     DSPHXW          Display lower half
        RTS                     Return to caller
        

        
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
        
        MOVE.L  SLOC,GBUFF      Store starting location in GBUFF for OP
        BSR     CMPRSS
        BRA     OP
        
PRINT   MOVE.L  (IOADDR),D0     Read memory location
        BSR     DSPHXL          Display as hex long
        MOVE.B  #6,D0           Display character
        MOVE.B  #TB,D1          Read tab
        TRAP    #15
        LEA     OPCDNM,A1       Read OP-code
        CLR.L   D0
        CMP.B   #$FF,(IOOPCD)   Test if OP-code exists
        BNE     BRGOOD
BRBAD   MOVE.B  #$87,IOOPCD
BRGOOD  MOVE.B  (IOOPCD),D0     Get offset
        ADD.L   D0,A1           Add offset
        MOVE.B  #14,D0          Display string until NULL character
        TRAP    #15

        MOVE.B  #6,D0           Display character
        MOVE.B  #TB,D1          Read tab
        TRAP    #15

        MOVE.B  #CR,D1
        TRAP    #15
        MOVE.B  #LF,D1
        TRAP    #15

        *DISPLAY IO OPERAND
        
        MOVE.L  GBUFF,A0        Set A0 to ELOC location
        CMPA.L  ELOC,A0         Compare next buffer to ending location
        BGE     DONE            Branch to DONE if >= ending location

        ADD.B   #1,LC
        CMP.B   #30,LC          Compare #30 to line counter
        BEQ     PAUSE           If ==, branch to PAUSE

        * Reset IO OP-code
        MOVE.B  #$FF,(IOOPCD)
        BRA     OP              Branch to OP for next instruction

PAUSE   LEA     MSSG4,A1        Display keypress prompt
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  #12,D0          Hide keyboard input
        MOVE.B  #0,D1
        TRAP    #15
        MOVE.B  #5,D0           Request keyboard input
        TRAP    #15
        MOVE.B  #12,D0          Show keyboard input
        MOVE.B  #1,D1
        TRAP    #15
        MOVE.B  #11,D0          Clear the screen
        MOVE.W  #$FF00,D1
        TRAP    #15
        LEA     HEADR,A1        Display header
        MOVE.B  #14,D0
        TRAP    #15
        CLR.B   (LC)            Reset line counter
        BRA     OP

DONE    LEA     MSSG5,A1        Display header
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  #9,D0
        TRAP    #15

*--------------------
*   OP
*--------------------

OP      MOVE.L  GBUFF,A0        Set A0 to GBUFF location
        MOVE.L  (A0),D0         Transfer data to memory
        MOVE.L  GBUFF,IOADDR    Set memory location for IO
        ADD.L   #4,(GBUFF)      Increment GBUFF by long


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
     
        BRA     BRBAD                 No mask matched, branch to BRBAD

*--------------------------
*  Instruction Subroutines
*--------------------------
BRADD
        MOVE.B  #$11,(IOOPCD)       Set OP-code name
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
        BRA     PRINT
BRADD1                
        MOVE.B  MSK_9AB,MODE      Get the register number
        BSR     DNMODE
        *Print '','
        BSR     EAMODE        
        BRA     PRINT

BRADDA
        MOVE.B  #$15,(IOOPCD)       Set OP-code name
        *Print ADDA
        *Print  .
        *Print  Size according to OPMODE
        *Print  tab
        BSR     EAMODE 
        *Print  ','
        MOVE.B  MSK_9AB,MODE      Get the register number
        BSR     DNMODE       
        BRA     PRINT
BRADDQ
        MOVE.B  #$1A,(IOOPCD)       Set OP-code name
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
        BRA     PRINT
BRAND   
        MOVE.B  #$3B,(IOOPCD)       Set OP-code name
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
        BRA     PRINT Jump to next instruction
ANDMODE1 *AND Dn, <ea>
        MOVE.B  MSK_9AB,MODE Copy the EA<register> into MODE
        BSR     DNMODE
        *Call function to print a COMMA ','
        BSR     EAMODE
        BRA     PRINT  Jump to next instruction

BRBTST
        MOVE.B  #$58,(IOOPCD)       Set OP-code name
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
        BRA     PRINT
BTSTIMMED        
        *Still need to figure out and finish coding
        BRA     PRINT

BRBCC   
        MOVE.B  #$6B,(IOOPCD)       Set OP-code name
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
        MOVE.B  #$6F,(IOOPCD)       Set OP-code name
        *Print BEQ
        *CMP DISP8 to get displacement
        *If 00 then 16 displacement
        *If FF then 32 displacement
        BRA     ENDBCC        
BRBLT   
        MOVE.B  #$73,(IOOPCD)       Set OP-code name
        *Print BLT
        *CMP DISP8 to get displacement
        *If 00 then 16 displacement
        *If FF then 32 displacement
        BRA     ENDBCC
BRBNE   
        MOVE.B  #$77,(IOOPCD)       Set OP-code name
        *Print BNE
        *CMP DISP8 to get displacement
        *If 00 then 16 displacement
        *If FF then 32 displacement
        BRA     ENDBCC
BRBHI
        MOVE.B  #$7B,(IOOPCD)       Set OP-code name
        *Print BHI
        *CMP DISP8 to get displacement
        *If 00 then 16 displacement
        *If FF then 32 displacement
ENDBCC  
        BRA     PRINT
BRCMP
        MOVE.B  #$5D,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_Bto0
        *Print  CMP
        *Print  .
        *Print  size according to opmode
        *Print  tab
        BSR     EAMODE
        *Print  ,
        MOVE.B  MSK_9AB,MODE Copy the EA<register> into MODE
        BSR     DNMODE
        BRA     PRINT Jump to next instruction       
BRCMPA
        MOVE.B  #$61,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_Bto0
        *Print  CMPA
        *Print  .
        *Print  size according to opmode
        *Print  tab
        BSR     EAMODE
        *Print  ,
        MOVE.B  MSK_9AB,MODE Copy the EA<register> into MODE
        BSR     ANMODE
        BRA     PRINT Jump to next instruction   
BRCMPI
        MOVE.B  #$66,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_7to0
        *Print  CMPI
        *Print  .
        *Print  size according to bits 67
        *Print  tab
        *Print  #
        *Print  data from memory
        *Print  ','
        BSR     EAMODE
        BRA     PRINT
BRRTS 
        MOVE.B  #$83,(IOOPCD)       Set OP-code name
        * Call Print TAB function '      '
        *LEA     _RTS, A1       Load 'RTS' to be printed
        MOVE.B    #0, D0        Load the length of message
        BRA     PRINT          Return to subroutine
BRLEA
        MOVE.B  #$37,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_Bto0
        *Print  LEA
        *Print  tab
        BSR     EAMODE
        *Print  ,
        MOVE.B  MSK_9AB,MODE Copy the EA<register> into MODE
        BSR     ANMODE        

BRJSR
        MOVE.B  #$7F,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_012
        BSR     EXTMSK_345
        *Print  JSR
        *Print  tab
        BSR     EAMODE
        BRA     PRINT
BRMOVE
        MOVE.B  #$00,(IOOPCD)       Set OP-code name
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
        BRA     PRINT          Go to next instruction

BRMOVEA 
        MOVE.B  #$05,(IOOPCD)       Set OP-code name
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
        BRA     PRINT          Get next instruction
BRMOVEM
        MOVE.B  #$0B,(IOOPCD)       Set OP-code name
        BRA     PRINT
BRASL
        MOVE.B  #$50,(IOOPCD)       Set OP-code name
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
        BRA     PRINT        
ASLMEMORY
        BSR     EXTMSK_012
        BSR     EXTMSK_345
        BSR     EAMODE
        BRA     PRINT

        BRA     PRINT
BRLSR
        MOVE.B  #$54,(IOOPCD)       Set OP-code name
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
        BRA     PRINT        
LSRMEMORY
        BSR     EXTMSK_012
        BSR     EXTMSK_345
        BSR     EAMODE
        BRA     PRINT

BRMULU
        MOVE.B  #$2D,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_Bto0
        *Print  MULU
        *Print  tab
        BSR     EAMODE
        *Print  ,
        MOVE.B  MSK_9AB,MODE      Get the register number
        BSR     DNMODE
        BRA     PRINT
BRDIVS
        MOVE.B  #$32,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_Bto0
        *Print  DIVS
        *Print  tab
        BSR     EAMODE
        *Print  ,
        MOVE.B  MSK_9AB,MODE      Get the register number
        BSR     DNMODE        
        BRA     PRINT
BREOR
        MOVE.B  #$43,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_Bto0
        *Print EOR
        *Print a tab
        MOVE.B  MSK_9AB, MODE     Copy the register Number
        BSR     DNMODE
        *Print a comma ','
        BSR     EAMODE
        BRA     PRINT          Get next instruction
BRORI
        MOVE.B  #$3F,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_7to0
        *Print  ORI
        *Print  tab
        *Print  #
        *Print  data according to size
        *Print  comma ','
        BSR     EAMODE
        BRA     PRINT
BREORI
        MOVE.B  #$47,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_7to0
        *Print  EORI
        *Print  tab
        *Print  #
        *Print  data according to size
        *Print  comma ','
        BSR     EAMODE
        BRA     PRINT
BRNOT
        MOVE.B  #$4C,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_7to0
        *Print NOT
        *Call function to print DOT '.'
        *Call function to print based on size (B/W/L)
        *Call function to print a TAB
        BSR     EAMODE
        BRA     PRINT
BRSUB
        MOVE.B  #$1F,(IOOPCD)       Set OP-code name
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
        BRA     PRINT             
BRSUB1    
        MOVE.B  MSK_9AB,MODE Load the register number
        BSR     DNMODE      
        *Print comma ','
        BSR     EAMODE
        BRA     PRINT      Get next instruction
BRSUBA
        MOVE.B  #$23,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_Bto0
        *Print  SUBA
        *Print  .
        *Print  Size according to MSK_678
        *Print  tab
        BSR     EAMODE  Print <EA>
        *Print  ,
        MOVE.B  MSK_9AB,MODE Load the register number
        BSR     ANMODE  Print <An>     
        BRA     PRINT
BRSUBI
        MOVE.B  #$28,(IOOPCD)       Set OP-code name
        BSR     EXTMSK_7to0
        *Print  SUBI
        *Print  .
        *Print  size according to bits 67
        *Print  tab
        *print  #
        *print  data *32/16/8
        *print  ','
        BSR     EAMODE
        BRA     PRINT

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
        MOVE.L  (GBUFF),D0                 Transfer data to memory
        MOVE.L  #%0000000111111111,D2   Mask
        BSR     EXTMSK                  Extract masked bits
        MOVE.B  D1,DISP8                Store masked bits
        RTS
EXTMSK_678      * 15 14 13 12 11 10 09[08 07 06]05 04 03 02 01 00
        MOVE.L  (GBUFF),D0                 Transfer data to memory
        MOVE.L  #%0000000111000000,D2   Mask
        BSR     EXTMSK                  Extract masked bits
        MOVE.B  D1,MSK_678              Store masked bits
        RTS                             Return to caller
        
EXTMSK_89AB     * 15 14 13 12 [11 10 09 08] 07 06 05 04 03 02 01 00
        MOVE.L  (GBUFF),D0                 Transfer data to memory
        MOVE.L  #%0000111100000000,D2   Mask
        BSR     EXTMSK                  Extract masked bits
        MOVE.B  D1,MSK_89AB              Store masked bits
        RTS                             Return to caller
        
EXTMSK_67      * 15 14 13 12 11 10 09 08 [07 06]05 04 03 02 01 00
        MOVE.L  (GBUFF),D0                 Transfer data to memory
        MOVE.L  #%0000000011000000,D2   Mask
        BSR     EXTMSK                  Extract masked bits
        MOVE.B  D1,MSK_67               Store masked bits
        RTS                             Return to caller

EXTMSK_CD       * 15 14[13 12]11 10 09 08 07 06 05 04 03 02 01 00
        MOVE.L  (GBUFF),D0
        MOVE.L  #%0011000000000000,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_CD
        RTS
        
EXTMSK_5        * 15 14 13 12 11 10 09 08 07 06[05]04 03 02 01 00
        MOVE.L  (GBUFF),D0
        MOVE.L  #%0000000000100000,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_5
        RTS
EXTMSK_8        * 15 14 13 12 11 10 09 [08] 07 06 05 04 03 02 01 00
        MOVE.L  (GBUFF),D0
        MOVE.L  #%0000000100000000,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_8
        RTS        
EXTMSK_012      * 15 14 13 12 11 10 09 08 07 06 05 04 03[02 01 00]
        MOVE.L  (GBUFF),D0
        MOVE.L  #%0000000000000111,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_012
        RTS
        
EXTMSK_345      * 15 14 13 12 11 10 09 08 07 06[05 04 03]02 01 00
        MOVE.L  (GBUFF),D0
        MOVE.L  #%0000000000111000,D2
        BSR     EXTMSK
        MOVE.B  D1,MSK_345
        RTS
        
EXTMSK_9AB      * 15 14 13 12[11 10 09]08 07 06 05 04 03 02 01 00
        MOVE.L  (GBUFF),D0
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
        BSR     DNMODE   
        LEA     _M0,A1
        MOVE.B  #14, D0
        *TRAP    #15
        RTS
JMP_M1
        *Need to print a Address Register
        *Call function to go to the address register to be printed
        BSR     ANMODE
        LEA     _M1,A1
        MOVE.B  #14, D0
        *TRAP    #15
        RTS
JMP_M2
        *Print (
        BSR     ANMODE
        *Print )
        LEA     _M2,A1
        MOVE.B  #14, D0
        *TRAP    #15
        RTS
JMP_M3
        *Call function to print a '(' paran
        BSR     ANMODE
        *Print )
        *Print +
        LEA     _M3,A1
        MOVE.B  #14, D0
        *TRAP    #15
        RTS
JMP_M4
        *Print -
        *Print (
        BSR     ANMODE
        *Print )
        LEA     _M4,A1
        MOVE.B  #14, D0
        *TRAP    #15
        RTS
JMP_M5
        LEA     _M5,A1
        MOVE.B  #14, D0
        *TRAP    #15
        RTS
JMP_M6 
        LEA     _M6,A1
        MOVE.B  #14, D0
        *TRAP    #15
        RTS
JMP_M7 
        *Call Print Pound Sign function
        *Retrieve value from Memory
        *Print value
        LEA     _M7,A1
        MOVE.B  #14, D0
        *TRAP    #15
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

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
GBUFF   DS.L    1       Pointer to next location in "Good buffer"
SLOC    DS.B    4       Starting location storage
ELOC    DS.B    4       Ending location storage

*-----I/O Memory-----
IOOPCD  DS.B    1       IO offset value for OPNAME
IOBDCD  DS.B    1       IO offset value for BAD OPNAME
IOSIZE  DS.B    1       IO size for OP code, or FF if none
IOADDR  DS.L    1       IO address value for instruction memory location
IOLC    DS.B    1       IO line counter for screen


* OP code name memory
* Example to display MULU:
*       LEA     OPNAME,A1
*       ADD.L   #$2D,A1
*       MOVE.B  #14,D0
*       TRAP    #15
*                NAME           DEC     HEX
OPNAME  DC.B    'MOVE',0        00      00
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
        DC.B    'MOVEQ',0       139     8B
        DC.B    'LSL',0         145     91
        DC.B    'ASR',0         149     95
        DC.B    'ADDI',0        153     99

IOOPSZ  DC.B    '.B',0          0       00
        DC.B    '.W',0          3       03
        DC.B    '.L',0          6,      06
        DC.B    '  ',0          9,      09

*-----EA Memory------
DMD     DS.B    1               Destination mode
DRG     DS.B    1               Destination register
SMD     DS.B    1               Source mode
SRG     DS.B    1               Source register

*--------------------

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

START   MOVE.B  #0,IOLC
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
* Flag set / clear: Sets or clears the flag
*
 
FLAGST  MOVE.W  #%100,CCR       Set the z-flag
        RTS                     Return to caller
FLAGCL  MOVE.W  #%000,CCR       Clear the z-flg
        RTS                     Return to caller

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
        CMP.L   D1,D2           Test if the input matched the mask
        BNE     *+8             If it didn't match, skip two lines
        MOVE.L  (SP)+,D1        Restore D1
        BRA     FLAGST          Set flag & return to caller
        MOVE.L  (SP)+,D1        Restore D1
        BRA     FLAGCL          Clear flag & return to caller

*
* Compare Mask: Strictly test an input to two masks allowing don't cares.
* Input value from D0, input 1 mask from D2, input 0 mask from D3, and modify z-flag
*

CMPMSK  
        MOVEM.L D0-D4,-(SP)     Push D1-D4 on stack
        MOVE.L  D0,D4           Copy input to D4
        AND.L   D2,D0           AND 1 mask to input
        CMP.L   D0,D2           Compare masked input to 1 mask
        BEQ     *+10            If it matched, skip two lines
        MOVEM.L (SP)+,D0-D4     If it didn't match, restore D1-D4
        BRA     FLAGCL          Clear flag & return to caller
        MOVE.L  D4,D0           Restore input
        NOT.L   D0              !input
        AND.L   D3,D0           AND 0 mask on input; effectively, NOR 0 mask to the input
        CMP.L   D0,D3           Compare masked input to 0 mask
        BNE     *+10            If it didn't match, skip to clear flag
        MOVEM.L (SP)+,D0-D4     If it matched, restore D1-D4
        BRA     FLAGST          Set flag & return to caller
        MOVEM.L (SP)+,D0-D4     Restore D1-D4
        BRA     FLAGCL          Clear flag & return to caller
        

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
* Display HEX Address: Display the hex from A1 according to the byte length in D2.L
*

DSPHXA  MOVEM.L D0-D2/A1,-(SP)  Push D0-D2, and A1 to stack
DSPHXLP DBRA    D2,*+8          Decrement count; if count is > 0, do not branch to return
        BRA     DSPHXRT         If count is <= 0, branch to return
        MOVE.B  (A1)+,D0        Get HEX byte in D0, post-increment A1
        BSR     HEX2ASCII       Get ASCII in D1
        ROL.W   #8,D1           Read first byte
        MOVE.B  #6,D0           Display char from D1.B
        TRAP    #15
        ROL.W   #8,D1           Read second byte
        TRAP    #15
        BRA     DSPHXLP         Loop back
DSPHXRT MOVEM.L (SP)+,D0-D2/A1  Else, restore values
        RTS                     Return to caller
        


*
* Display HEX Nibble: Display the hex from D0.B to screen
*

DSPHXN  MOVEM.L D0/D1,-(SP)     Push D0 and D1 to stack
        BSR     HEX2ASCII       Get ASCII in D1
        MOVE.B  #6,D0           Set trap #6 to read single char from D1.B
        TRAP    #15
        MOVEM.L (SP)+,D0/D1     Restore D0 and D1
        RTS                     Return to caller

*
* Display HEX Word: Display the hex from D0.W to screen
*

DSPHXW  MOVEM.L D0-D2,-(SP)     Push D0-D2 to stack
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

DISPOP  MOVEM.L D0-D2,-(SP)         Push D0-D2 to stack
        MOVE.B  #6,D0               Display character
        MULU.W  #4,D2
        JMP     MODTBL(PC,D2.W)     Jump to mode
MODTBL  BRA     DISP0               Dn
        BRA     DISP1               An
        BRA     DISP2               (An)
        BRA     DISP3               (An)+
        BRA     DISP4               -(An)
        BRA     DISP5               (d,An)
        BRA     DISP6               (d,An,Xn)
        BRA     DISP7               (XXX).W/(XXX).L/(d,PC)/(d,PC,Xn)/#data
* Dn	    	000	XXX
DISP0   MOVE.B  #'D',D1             Read D
        TRAP    #15
        MOVE.L  D3,D0               Read reg from D3
        BSR     DSPHXN              Display as hex nibble
        BRA     DISPD               Branch to return
* An		    001	XXX
DISP1   MOVE.B  #'A',D1             Read A
        TRAP    #15
        MOVE.L  D3,D0               Read reg from D3
        BSR     DSPHXN              Display as hex byte
        BRA     DISPD               Branch to return
* (An)		    010	XXX
DISP2   MOVE.B  #'(',D1             Read (
        TRAP    #15
        MOVE.B  #'A',D1             Read A
        TRAP    #15
        MOVE.L  D3,D0               Read reg from D3
        BSR     DSPHXN              Display as hex nibble
        MOVE.B  #6,D0               Display character
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPD               Branch to return
* (An)+		    011	XXX
DISP3   MOVE.B  #'(',D1             Read (
        TRAP    #15
        MOVE.B  #'A',D1             Read A
        TRAP    #15
        MOVE.L  D3,D0               Read reg from D3
        BSR     DSPHXN              Display as hex nibble
        MOVE.B  #6,D0               Display character
        MOVE.B  #')',D1             Read )
        TRAP    #15
        MOVE.B  #'+',D1             Read +
        TRAP    #15
        BRA     DISPD               Branch to return
* -(An)		    100	XXX
DISP4   MOVE.B  #'-',D1             Read +
        TRAP    #15
        MOVE.B  #'(',D1             Read (
        TRAP    #15
        MOVE.B  #'A',D1             Read A
        TRAP    #15
        MOVE.L  D3,D0               Read reg from D3
        BSR     DSPHXN              Display as hex nibble
        MOVE.B  #6,D0               Display character
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPD               Branch to return
* (d,An)		101	XXX
DISP5   MOVE.B  #'(',D1             Read (
        TRAP    #15
        *----TODO---*
        * Display d *
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        MOVE.B  #'A',D1             Read A
        TRAP    #15
        *----TODO---*
        * Display A *
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPD               Branch to return
* (d,An,Xn)	    110	XXX
DISP6   MOVE.B  #'(',D1             Read (
        TRAP    #15
        *----TODO---*
        * Display d *
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        MOVE.B  #'A',D1             Read A
        TRAP    #15
        *----TODO---*
        * Display A *
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        MOVE.B  #'X',D1             Read X
        TRAP    #15
        *----TODO---*
        * Display X *
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPD               Branch to return
* (XXX).W/(XXX).L/(d,PC)/(d,PC,Xn)/#data
DISP7   MULU.W  #4,D3
        JMP     REGTBL(PC,D3.W)     Jump to reg
REGTBL  BRA     DISP8               (XXX).W
        BRA     DISP9               (XXX).L
        BRA     DISPA               (d,PC)
        BRA     DISPB               (d,PC,Xn)
        BRA     DISPC               #data
* (XXX.W)		111	000
DISP8   
        MOVE.B  #'$',D1             Read $
        TRAP    #15
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        CLR.L   D2
        MOVE.B  #2,D2               Read word size to D2
        BSR     DSPHXA              Display address
        ADD.L   D2,(IOADDR)         Advance IO address by word
        BRA     DISPD               Branch to return
* (XXX.L)		111	001
DISP9   MOVE.B  #'$',D1             Read $
        TRAP    #15
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        CLR.L   D2
        MOVE.B  #4,D2               Read long size to D2
        BSR     DSPHXA              Display address
        ADD.L   D2,(IOADDR)         Advance IO address by long
        BRA     DISPD               Branch to return
* (d,PC)		111	010
DISPA   MOVE.B  #'(',D1             Read (
        TRAP    #15
        *----TODO---*
        * Display d *
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        MOVE.B  #'P',D1             Read P
        TRAP    #15
        MOVE.B  #'C',D1             Read C
        TRAP    #15
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPD
* (d,PC,Xn)		111	011
DISPB   MOVE.B  #'(',D1             Read (
        TRAP    #15
        *----TODO---*
        * Display d *
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        MOVE.B  #'P',D1             Read P
        TRAP    #15
        MOVE.B  #'C',D1             Read C
        TRAP    #15
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        MOVE.B  #'X',D1             Read X
        TRAP    #15
        *----TODO---*
        * Display X *
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPD               Branch to return
* #<data>		111	100
DISPC   MOVE.B  #'#',D1             Read #
        TRAP    #15
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        CLR.L   D2
        MOVE.B  (IOSIZE),D2         Read instruction size to D2
        MULU.W  #2,D2               Translate size to value
        BSR     DSPHXA              Display address
        ADD.L   D2,A1               Advance A1 by instruction size
        MOVE.L  A1,(IOADDR)         Move A1 to IOADDR
        BRA     DISPD               Branch to return
DISPD   MOVEM.L (SP)+,D0-D2         Restore D0-D2
        RTS                         Return to caller
        
BRBAD   MOVE.B  (IOOPCD),(IOBDCD)   Move OPCODE to BAD OPCODE
        MOVE.B  #$87,(IOOPCD)       Set OPCODE to BAD
        ADD.L   #$2,(GBUFF)         Advance the buffer
PRINT   *----TODO----*
        * If OP code exists as BAD and BAD OPCODE don't exist, assume that the last
        * OP display was BAD, and display then next word as raw data
        CMP.B   #$FF,(IOOPCD)       Test if OP code exists
        BEQ     BRBAD               If it does not, display BAD

        MOVE.L  (IOADDR),D0         Read memory location
        BSR     DSPHXL              Display as hex long
        MOVE.B  #6,D0               Display character
        MOVE.B  #TB,D1              Read tab
        TRAP    #15

        CLR.L   D0
        LEA     OPNAME,A1           Read OP-code
        MOVE.B  (IOOPCD),D0         Get offset
        ADD.L   D0,A1               Add offset
        MOVE.B  #14,D0              Display string until NULL char
        TRAP    #15
    
        CMP.B   #$FF,(IOBDCD)       Test if BAD OP code exists
        BEQ     *+50                If it doesn't exist, don't display it
        MOVE.B  #6,D0               Display character
        MOVE.B  #' ',D1             Read space
        TRAP    #15
        MOVE.B  #'(',D1             Read (
        TRAP    #15
        LEA     OPNAME,A1           Read OP-code
        MOVE.B  (IOBDCD),D0         Get offset
        ADD.L   D0,A1               Add offset
        MOVE.B  #14,D0              Display string until NULL char
        TRAP    #15
        MOVE.B  #6,D0               Display character
        MOVE.B  #'?',D1
        TRAP    #15                 Read ?
        MOVE.B  #')',D1             Read )
        TRAP    #15

        LEA     IOOPSZ,A1           Read OP code size
        MOVE.B  #$03,D0             Set size to 3
        CMP.B   #$FF,(IOSIZE)       Test if OP size exists
        BEQ     *+6                 If OP size doesn't exist, skip the next line
        MOVE.B  (IOSIZE),D0         If OP size exists, move it to D0
        MULU.W  #$3,D0              Multiply size by 3 for correct offset
        ADD.L   D0,A1               Add offset
        MOVE.B  #14,D0              Display string until NULL char
        TRAP    #15

        MOVE.B  #6,D0               Display character
        MOVE.B  #TB,D1              Read tab
        TRAP    #15

        ADD.L   #2,(IOADDR)         Move memory location past first word

        CLR.B   D4                  Set source to false
        CLR.W   D2
        CLR.W   D3
        MOVE.B  (SMD),D2            Read source mode to D2
        CMP.B   #$FF,D2             Test if it exists
        BEQ     NOSRC               If it does not exist, do not display source
        MOVE.B  (SRG),D3            Read source reg to D3
        CMP.B   #$FF,D3             Test if it exists
        BEQ     NOSRC               If it does not exist, do not display source
        BSR     DISPOP              If both mode & register exist, display accordingly
        MOVE.B  #1,D4               Set source to true

NOSRC   CLR.W   D2
        CLR.W   D3
        MOVE.B  (DMD),D2            Read dest mode to D2
        CMP.B   #$FF,D2             Test if it exists
        BEQ     NODST               If it does not exist, do not display dest
        MOVE.B  (DRG),D3            Read dest reg to D3
        CMP.B   #$FF,D3             Test if it exists
        BEQ     NODST               If it does not exist, do not display dest

        MOVE.B  #6,D0               Display character
        MOVE.B  #',',D1             Read comma
        CMP.B   #1,D4               Test if source was displayed
        BNE     *+2                 If it was not displayed, don't display a comma
        TRAP    #15                 If it was displayed, display a comma

        BSR     DISPOP              If both mode & register exist, display accordingly

NODST   MOVE.B  #6,D0               Display character
        MOVE.B  #TB,D1              Read tab
        TRAP    #15

        MOVE.B  #CR,D1
        TRAP    #15
        MOVE.B  #LF,D1
        TRAP    #15

        *DISPLAY IO OPERAND
        
        MOVE.L  GBUFF,A0            Set A0 to ELOC location
        CMPA.L  ELOC,A0             Compare next buffer to ending location
        BGE     DONE                Branch to DONE if >= ending location

        ADD.B   #1,IOLC
        CMP.B   #30,IOLC            Compare #30 to line counter
        BEQ     PAUSE               If ==, branch to PAUSE

        * Reset IO instruction values
        MOVE.B  #$FF,(SMD)
        MOVE.B  #$FF,(SRG)
        MOVE.B  #$FF,(DMD)
        MOVE.B  #$FF,(DRG)
        MOVE.B  #$FF,(IOOPCD)
        MOVE.B  #$FF,(IOBDCD)
        MOVE.B  #$FF,(IOSIZE)

        BRA     OP                  Branch to OP for next instruction

PAUSE   LEA     MSSG4,A1            Display keypress prompt
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  #12,D0              Hide keyboard input
        MOVE.B  #0,D1
        TRAP    #15
        MOVE.B  #5,D0               Request keyboard input
        TRAP    #15
*----TODO----*
* Test if keycode was for ENTER
        MOVE.B  #12,D0              Show keyboard input
        MOVE.B  #1,D1
        TRAP    #15
        MOVE.B  #11,D0              Clear the screen
        MOVE.W  #$FF00,D1
        TRAP    #15
        LEA     HEADR,A1            Display header
        MOVE.B  #14,D0
        TRAP    #15
        CLR.B   (IOLC)              Reset line counter
        BRA     OP

DONE    LEA     MSSG5,A1            Display header
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  #9,D0
        TRAP    #15

*--------------------
*   OP
*--------------------

* Swap data registers: Swaps d0 and d1
SWAPDR  MOVE.L  D0,-(SP)
        MOVE.L  D1,D0
        MOVE.L  (SP)+,D1
        RTS

OP      MOVE.L  GBUFF,A0        Set A0 to GBUFF location
        MOVE.W  (A0)+,D0        Transfer word data to D0, post-increment location
        MOVE.W  (A0),D1         Transfer next word data to D1
        MOVE.L  GBUFF,IOADDR    Set memory location for IO


        * Mask bits to determine OP-code and branch correspondingly-- high order bits are checked first
        
        * LSL:    1110001111XXXXXX
        MOVE.W  #%1110001111000000,D2
        MOVE.W  #%0001110000000000,D3
        BSR     CMPMSK
        BEQ     BRLSL

        * LSL:    1110XXX1XXX01XXX
        MOVE.W  #%1110000100001000,D2
        MOVE.W  #%0001000000010000,D3
        BSR     CMPMSK
        BEQ     BRLSL

        * LSR:    1110001011XXXXXX
        MOVE.W  #%1110001011000000,D2
        MOVE.W  #%0001110100000000,D3
        BSR     CMPMSK
        BEQ     BRLSR

        * LSR:    1110XXX0XXX01XXX
        MOVE.W  #%1110000000001000,D2
        MOVE.W  #%0001000100010000,D3
        BSR     CMPMSK
        BEQ     BRLSR

        * ASL:    1110000111XXXXXX
        MOVE.W  #%1110000111000000,D2
        MOVE.W  #%0001111000000000,D3
        BSR     CMPMSK
        BEQ     BRASL

        * ASL:    1110XXX1XXX00XXX
        MOVE.W  #%1110000100000000,D2
        MOVE.W  #%0001000000011000,D3
        BSR     CMPMSK
        BEQ     BRASL

        * ASR:    1110000011XXXXXX
        MOVE.W  #%1110000011000000,D2
        MOVE.W  #%0001111100000000,D3
        BSR     CMPMSK
        BEQ     BRASR

        * ASR:    1110XXX0XXX00XXX
        MOVE.W  #%1110000000000000,D2
        MOVE.W  #%0001000100011000,D3
        BSR     CMPMSK
        BEQ     BRASL

        * ADD:    1101XXXXXXXXXXXX
        * ADDA
        MOVE.W  #%1101000000000000,D2
        MOVE.W  #%0010000000000000,D3
        BSR     CMPMSK
        BEQ     BRADD

        * ADDI:   00000110XXXXXXXX
        MOVE.W  #%0000011000000000,D2
        MOVE.W  #%1111100100000000,D3
        BSR     CMPMSK
        BEQ     BRADDI

        * AND:    1100XXXXXXXXXXXX
        MOVE.W  #%1100000000000000,D2
        MOVE.W  #%0011000000000000,D3
        BSR     CMPMSK
        BEQ     BRAND

        * MULU:   0100110000XXXXXX
        MOVE.W  #%0100110000000000,D2
        MOVE.W  #%1011001111000000,D3
        BSR     CMPMSK
        BNE     *+26
        BSR     SWAPDR
        * nxt wrd 0XXX0X0000000XXX
        MOVE.W  #%0000000000000000,D2
        MOVE.W  #%1000101111111000,D3
        BSR     CMPMSK
        BEQ     BRMULU
        BSR     SWAPDR

        * CMP:    1011XXXXXXXXXXXX
        * CMPA
        MOVE.W  #%1011000000000000,D2
        MOVE.W  #%0100000000000000,D3
        BSR     CMPMSK
        BEQ     BRCMP

        * CMPI:   00001100XXXXXXXX
        MOVE.W  #%0000110000000000,D2
        MOVE.W  #%1111001100000000,D3
        BSR     CMPMSK
        BEQ     BRCMPI

        * EOR:    1011XXXXXXXXXXXX
        MOVE.W  #%1011000000000000,D2
        MOVE.W  #%0100000000000000,D3
        BSR     CMPMSK
        BEQ     BREOR

        * EORI:   00001010XXXXXXXX
        MOVE.W  #%0000101000000000,D2
        MOVE.W  #%1111010100000000,D3
        BSR     CMPMSK
        BEQ     BREORI

        * DIVS:   0100110001XXXXXX
        MOVE.W  #%0100110001000000,D2
        MOVE.W  #%1011001110000000,D3
        BSR     CMPMSK
        BNE     *+26
        BSR     SWAPDR
        * nxt wrd 0XXX1X0000000XXX
        MOVE.W  #%0000100000000000,D2
        MOVE.W  #%1000001111111000,D3
        BSR     CMPMSK
        BEQ     BRDIVS
        BSR     SWAPDR

        * MOVEQ:  0111XXX0XXXXXXXX
        MOVE.W  #%0111000000000000,D2
        MOVE.W  #%1000000100000000,D3
        BSR     CMPMSK
        BEQ     BRMOVEQ

        * BCC:    01100000XXXXXXXX
        MOVE.W  #%0110000000000000,D2
        MOVE.W  #%1001111100000000,D3
        BSR     CMPMSK
        BEQ     BRBCC

        * ADDQ:   0101XXXXXXXXXXXX
        MOVE.W  #%0101000000000000,D2
        MOVE.W  #%1010000000000000,D3
        BSR     TSTMSK
        BEQ     BRADDQ

        * RTS:    0100111001110101
        CMP.W   #%0100111001000101,D0
        BEQ     BRRTS

        * JSR:    0100111010XXXXXX
        MOVE.W  #%0100111010000000,D2
        MOVE.W  #%1011000101000000,D3
        BSR     CMPMSK
        BEQ     BRJSR

        * NOT:    01000110XXXXXXXX
        MOVE.W  #%0100011000000000,D2
        MOVE.W  #%1011100100000000,D3
        BSR     CMPMSK
        BEQ     BRNOT


        * LEA:    0100XXX111XXXXXX
        MOVE.W  #%0100000111000000,D2
        MOVE.W  #%1011000000000000,D3
        BSR     CMPMSK
        BEQ     BRLEA

        * MOVEM:  01001X001XXXXXXX
        MOVE.W  #%0100100010000000,D2
        MOVE.W  #%1011001100000000,D3
        BSR     CMPMSK
        BEQ     BRMOVEM

        * MOVE:   00XXXXXXXXXXXXXX
        MOVE.W  #%0000000000000000,D2
        MOVE.W  #%1100000000000000,D3
        BSR     CMPMSK
        BEQ     BRMOVE

        * CMPI:   00001100XXXXXXXX
        MOVE.W  #%0000110000000000,D2
        MOVE.W  #%1111001100000000,D3
        BSR     CMPMSK
        BEQ     BRCMPI

        * BTST:   0000100000XXXXXX
        MOVE.W  #%0000100000000000,D2
        MOVE.W  #%1111011111000000,D3
        BSR     CMPMSK
        BNE     *+26
        BSR     SWAPDR
        * nxt wrd 00000000XXXXXXXX
        MOVE.W  #%0000000000000000,D2
        MOVE.W  #%1111111100000000,D3
        BSR     CMPMSK
        BEQ     BRBTST
        BSR     SWAPDR

        * ORI:    00001010XXXXXXXX
        MOVE.W  #%0000101000000000,D2
        MOVE.W  #%1111010100000000,D3
        BSR     CMPMSK
        BEQ     BRORI

        * SUB:    1001XXXXXXXXXXXX
        * SUBA, SUBI
        MOVE.W  #%1001000000000000,D2
        MOVE.W  #%0110000000000000,D3
        BSR     CMPMSK
        BEQ     BRSUB
     
        BRA     BRBAD           No mask matched, branch to BRBAD

*--------------------------
*  Instruction Subroutines
*--------------------------
*
* Advance Buffer: Advances A0 based on the REG & MODE (in that order)
* Input reg & mode in D1.B, output difference to D2
* Todo? May be better to copy buffer to A1 and advance A1
*

ADVBFR  MOVE.B  D1,-(SP)        Push D1 to the stack
        MOVE.L  (GBUFF),D2      Copy buffer to D2
        CMP.B   #$07,D1         Test 000 111 = Address (Word)
        BNE.S   *+6             Branch to next test
        ADD.L   #$2,(GBUFF)     Advance buffer by word
        CMP.B   #$0F,D1         Test 001 111 = Address (Long)
        BNE.S   *+6             Branch to next test
        ADD.L   #$4,(GBUFF)     Advance buffer by long
        CMP.B   #$27,D1         Test 100 111 = Immediate (OP code size)
        BNE.S   ADVRET          Branch to return
        MOVE.B  (IOSIZE),D1     Else, read size to D1
        CMP.B   #$1,D0          Test 0 = Byte
        BNE.S   *+6             Branch to next test
        ADD.L   #$2,(GBUFF)     Advance buffer by word (00XBBX)
        CMP.B   #$1,D1          Test 1 = Word
        BNE.S   *+6             Branch to next test
        ADD.L   #$2,(GBUFF)     Advance buffer by word        
        CMP.B   #$2,D1          Test 2 = Long
        BNE.S   *+6             Branch to return method
        ADD.L   #$4,(GBUFF)     Advance buffer by long
ADVRET  NEG.L   D2              Negate original buffer
        ADD.L   (GBUFF),D2      Add buffer to get difference
        MOVE.B  (SP)+,D1        Restore D1
        RTS                     Return to caller


*
* Standard Size: Test the standard size code
* Inputs size from D0.B, outputs size to IOSIZE (if found)
* Set Z-flag if size was found, or clear Z-flag if size was not found
*

SSIZE   MOVE.B  D1,-(SP)    Push D1 to stack
        MOVE.B  #$FF,D1     Set size to null
        CMP.B   #%01,D0     01 = Byte
        BNE.S   *+6         Branch to next test
        MOVE.B  #$0,D1      Set size to byte
        CMP.B   #%11,D0     11 = Word
        BNE.S   *+6         Branch to next test
        MOVE.B  #$1,D1      Set size to word
        CMP.B   #%10,D0     10 = Long
        BNE.S   *+6         Branch to next test
        MOVE.B  #$2,D1      Set size to long
        CMP.B   #$FF,D1     Test if size was found
        BEQ     *+18        If it was not found, branch to clear flag      
        MOVE.B  D1,(IOSIZE) If it was found, store size in IOSIZE
        MOVE.B  (SP)+,D1    Restore D1
        BRA     FLAGST      Set flag & return to caller
        MOVE.B  (SP)+,D1    Restore D1
        BRA     FLAGCL      Clear flag & return to caller

*
* OP Size: Test the OP size code
* Inputs size from D0.B, outputs size to IOSIZE (if found), outputs 0 to D1.B for Dn, or 1 to D1.B for <ea> 
* Set Z-flag if size was found, or clear Z-flag if size was not found
* OPM (OP-MODE):  Byte | Word | Long | Operation
*                  000 |  001 |  010 | <ea> + Dn -> Dn
*                  100 |  101 |  110 | Dn + <ea> -> <ea>
*

OPSIZE  MOVE.B  (DMD),D0    Get the OP mode from dest mode
        MOVE.B  #0,D1       Move 0 to D1 for Dn
        CMP.B   #4,D0       Compare OP mode to 4
        BNE.S   *+18        Branch to next test
        SUB.B   #4,D0       Subtract 4
        MOVE.B  #1,D1       Move 1 to D1 for <EA>
        MOVE.B  #$FF,D1     Set size to null
        CMP.B   #%000,D0    000 = Byte
        BNE.S   *+6         Branch to next test
        MOVE.B  #$0,D1      Set size to byte
        CMP.B   #%001,D0    001 = Word
        BNE.S   *+6         Branch to next test
        MOVE.B  #$1,D1      Set size to word
        CMP.B   #%010,D0    010 = Long
        BNE.S   *+6         Branch to next test
        MOVE.B  #$2,D1      Set size to long
        CMP.B   #$FF,D1     Test if size was found
        BEQ     *+14        If it was not found, branch to clear flag
        MOVE.B  D1,(IOSIZE) If it was found, store size in IOSIZE
        BRA     FLAGST      Set flag & return to caller
        BRA     FLAGCL      Clear the flag & return to caller

*
* Extract destination: Extracts destination mode to DMD and destination register to DRG from instruction in A0.W
* Outputs a combination of mode & reg in D1.B
*

EXDST   MOVEM.L D0/D2,-(SP)     Push D0 and D2 to stack
        MOVE.W  (A0),D0         Move instruction word to D0
        MOVE.L  #$1C0,D2        Extract dest mode at 0000000111000000
        BSR     EXTMSK          Get dest mode to D1
        MOVE.B  D1,(DMD)        Move dest mode to DMD
        MOVE.L  #$E00,D2        Extract dest reg at 0000111000000000
        BSR     EXTMSK          Get dest reg to D1
        MOVE.B  D1,(DRG)        Move dest reg to (DRG)
        LSL.B   #3,D1           Shift the reg 3 bits left
        OR.B    (DMD),D1        Add mode after reg
        MOVEM.L (SP)+,D0/D2     Restore D0 and D2
        RTS                     Return to caller

*
* Extract source: Extracts source mode and register
* Inputs instruction from A0, outputs mode to SMD and register to SRG
* Outputs a combination of mode & reg in D1.B
*

EXSRC   MOVEM.L D0/D2,-(SP)     Push D0 and D2 to stack
        MOVE.W  (A0),D0         Move instruction word to D0
        MOVE.L  #$38,D2         Extract src mode at 0000000000111000
        BSR     EXTMSK          Get src mode to D1
        MOVE.B  D1,(SMD)        Move src mode to (OMD)
        MOVE.L  #$7,D2          Extract src reg at 0000000000000111
        BSR     EXTMSK          Get src reg to D1
        MOVE.B  D1,(SRG)        Move src reg to (ORG)
        LSL.B   #3,D1           Shift the reg 3 bits left
        OR.B    (SMD),D1        Add mode after reg
        MOVEM.L (SP)+,D0/D2     Restore D0 and D2
        RTS                     Return to caller

*
* ADD: 1101|REG|OPM|EAM|EAR
*

BRADD   MOVE.B  #$11,(IOOPCD)   Set OP-code name

        MOVE.L  GBUFF,A0        Point A0 to GBUFF

        BSR     EXSRC           Extract EA mode & register
        BSR     EXDST           Extract OP mode & register
        
        CMP.B   #%011,(DMD)     Compare 011 to OP mode
        BNE.S   *+8             Branch to next test
        MOVE.B  #1,(IOSIZE)     Set size to word
        CMP.B   #%111,(DMD)     Compare 111 to OP mode
        BNE.S   *+8             Branch to next test
        MOVE.B  #2,(IOSIZE)     Set size to long
        CMP.B   #$FF,(IOSIZE)   Test if size was found
        BNE     BRADDA          If size was found, branch to BRADDA        

        BSR     OPSIZE          If size was not found, translate OP mode
        BNE     BRBAD           If size was not found, branch to BAD

        *CMP.B   #1,D1          Compare destination mode to <EA>

        ADD.L   #$2,(GBUFF)     Advace buffer
        BRA     PRINT           Go to next instruction

*
* ADDA: 1101|REG|OPM|EAM|EAR
*

BRADDA  MOVE.B  #$15,(IOOPCD)   Set OP-code name
        ADD.L   #$2,(GBUFF)     Advance buffer
        BRA     PRINT           Go to next instruction

BRADDQ  MOVE.B  #$1A,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRADDI  MOVE.B  #$99,(IOOPCD)       Set OP-code name
        BRA     BRBAD               Not supported

BRAND   MOVE.B  #$3B,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRBTST  MOVE.B  #$58,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRBCC   MOVE.B  #$6B,(IOOPCD)       Set OP-code name
        MOVE.L  GBUFF,A0
        MOVE.W  (A0),D0
        MOVE.L  #%11110000,D2
        BSR     EXTMSK
        CMP.B   #%0110,D1
        BNE     BRBAD
       
       * CMP.B   #7,D4
       * BEQ     BRBEQ
       * CMP.B   #13,D4
       * BEQ     BRBLT
       * CMP.B   #6,D4
       * BEQ     BRBNE
       * CMP.B   #2,D4
       * BEQ     BRBHI
        BRA     PRINT

BRBEQ   MOVE.B  #$6F,(IOOPCD)       Set OP-code name
        BRA     PRINT
        
BRBLT   MOVE.B  #$73,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRBNE   MOVE.B  #$77,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRBHI   MOVE.B  #$7B,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRCMP   MOVE.B  #$5D,(IOOPCD)       Set OP-code name
        BRA     PRINT
       
BRCMPA  MOVE.B  #$61,(IOOPCD)       Set OP-code name
        BRA     PRINT
  
BRCMPI  MOVE.B  #$66,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRRTS   MOVE.B  #$83,(IOOPCD)       Set OP-code name
        BRA     PRINT               Next instruction

BRLEA   MOVE.B  #$37,(IOOPCD)       Set OP-code name
        BRA     PRINT  

BRJSR   MOVE.B  #$7F,(IOOPCD)       Set OP-code name
        BRA     PRINT
        
*
* Move: 00|SZ|DRG|DMD|SMD|SRG
*

BRMOVE  MOVE.B  #$00,(IOOPCD)   Set OP-code name

        MOVE.L  #$3000,D2       Extract size at 0011000000000000
        BSR     EXTMSK          Get the size to D1
        MOVE.B  D1,D0           Move size to D0
        BSR     SSIZE           Translate size
        BNE     BRBAD           If size was not found, branch to BAD

        MOVE.L  GBUFF,A0        Point A0 to GBUFF

        BSR     EXDST           Extract destination mode & register
        BSR     ADVBFR          Advance the buffer accordingly

        BSR     EXSRC           Extract source mode & register
        BSR     ADVBFR          Advance the buffer accordingly

        CMP.B   #1,(DMD)        Test if the dest mode == 001
        BEQ     BRMOVEA         If the dest mode is equal, branch to BRMOVEA

        ADD.L   #$2,(GBUFF)     Advance buffer
        BRA     PRINT           Go to next instruction

BRMOVEA MOVE.B  #$05,(IOOPCD)   Set Op-code name
        ADD.L   #$2,(GBUFF)     Advance buffer
        BRA     PRINT           Go to next instruction

BRMOVEM ADD.L   #$8,(GBUFF)
        MOVE.B  #$0B,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRMOVEQ MOVE.B  #$8B,(IOOPCD)       Set OP-code name
        BRA     BRBAD               Not supported

BRASL   MOVE.B  #$50,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRASR   MOVE.B  #$95,(IOOPCD)       Set OP-code name
        BRA     BRBAD               Not supported

BRLSL   MOVE.B  #$91,(IOOPCD)       Set OP-code name
        BRA     BRBAD

BRLSR   MOVE.B  #$54,(IOOPCD)       Set OP-code name
        BRA     PRINT 

BRMULU  MOVE.B  #$2D,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRDIVS  MOVE.B  #$32,(IOOPCD)       Set OP-code name     
        BRA     PRINT

BREOR   MOVE.B  #$43,(IOOPCD)       Set OP-code name
        BRA     PRINT               Get next instruction

BRORI   MOVE.B  #$3F,(IOOPCD)       Set OP-code name
        BRA     PRINT

BREORI  MOVE.B  #$47,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRNOT   MOVE.B  #$4C,(IOOPCD)       Set OP-code name
        BRA     PRINT

BRSUB   MOVE.B  #$1F,(IOOPCD)       Set OP-code name
        BRA     PRINT        

BRSUBA  MOVE.B  #$23,(IOOPCD)       Set OP-code name   
        BRA     PRINT

BRSUBI  MOVE.B  #$28,(IOOPCD)       Set OP-code name
        BRA     PRINT

        END     START

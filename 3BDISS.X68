        INCLUDE 'TEST.x68'
*----------------------------------------------------------------------------
* Title      : 3B Disassembler
* Written by : The Three Bears: Joseph Schooley, Nguyen Tong, Terence Calhoun
* Date       : 11/30/2013
* Description: A Motorola MC68000 Microprocessor Disassembler 
*----------------------------------------------------------------------------
        ORG     $1000
CR      EQU     $0D         ASCII: carriage return
LF      EQU     $0A         ASCII: line feed
TB      EQU     $09         ASCII: horizontal tab
MNADDR  EQU     $7000       Min address
MXADDR  EQU     $00FFFFFF   Max address

GBUFF   DS.L    1           Pointer to next location in "Good buffer"
SLOC    DS.B    4           Starting location storage
ELOC    DS.B    4           Ending location storage

*-----I/O Memory-----
IOOPCD  DS.B    1           IO offset value for OPNAME, or FF if none
IOBDCD  DS.B    1           IO offset value for BAD OPNAME, or FF if none
IOSIZE  DS.B    1           IO size for OP code, or FF if none
IOADDR  DS.L    1           IO address value for instruction memory location
IOLC    DS.B    1           IO line counter for screen
QDATA   DS.B    1           OP immediate data for xxxxQ instructions


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
RGMD    DS.B    1               Last register + mod (00REGMOD)
DIS     DS.B    1               Last displacement

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
MSSG1   DC.B    'Enter the starting location of the code to be disassembled, or leave it blank',CR,LF,'for the starting address:',0
MSSG2   DC.B    'Enter the ending location of the code to be disassembled, or leave it blank',CR,LF,'for the ending address:',0
MSSG4   DC.B    'Press any key for the next page.',0
MSSG5   DC.B    'You have reached the end of the program.',0
HEADR   DC.B    'Address      OP-Code    Operand',CR,LF,0
ERR0    DC.B    'The input address was too small.',CR,LF,0
ERR1    DC.B    'The input address was too big.',CR,LF,0

START   MOVE.B  #0,IOLC
        *JMP     $7000
        LEA     MSSG0,A1        Welcome message
        MOVE.B  #14,D0
        TRAP    #15
        BRA     PRMPT1

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

CMPMSK  MOVEM.L D0-D4,-(SP)     Push D1-D4 on stack
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

        CMP.L   #$00FFFFFF,D0   Check if input was NULL
        BNE     *+14            If the input was not null, branch to convert input
        MOVE.L  #MNADDR,(SLOC)  If the input was null, move the min address to SLOC
        BRA     PRMPT2          Branch to the next prompt
        
        BSR     ASCII2HEX       Convert D0 to HEX in D1
        
        MOVE.L  D1,(A1)         Set SLOC to HEX value
                        
        CMP.L   #0,D1           Compare starting location to 0
        BEQ     DONE            End program if 0
        
        CMP.L   #MNADDR,D1      Compare starting location to min
        BLO     ILL0            Branch to ILL0 if < min
        
        CMP.L   #MXADDR,D1      Compare ending location to max
        BHS     ILL1            Branch to ILL1 if >= max
                
        BRA     PRMPT2          Branch to the next prompt

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
        
        MOVE.L  (ELOC),D0       Move input to D0

        CMP.L   #$00FFFFFF,D0   Check if input was NULL
        BNE     *+14            If the input was not null, branch to convert input
        MOVE.L  #MXADDR,(ELOC)  If the input was null, move the max address to ELOC
        BRA     PRMPTDN         Branch to prompt done
        
        BSR     ASCII2HEX       Convert D0 to HEX in D1
        
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
        
PRMPTDN MOVE.L  SLOC,GBUFF      Store starting location in GBUFF for OP
        BRA     DSPHDR          Branch to display method

*
* Display string: Displays string until NULL char
* Input string at A1, output length of string at D1.B
* Max length: 255
*
        
DSPSTR  MOVEM.L D0-D2/A1,-(SP)  Push D0-D2, and A1 to stack
        MOVE.L  #255,D2         Set count to 255
DSPSTLP DBRA    D2,*+8          Decrement count; if count is > 0, do not branch to return
        BRA     DSPSTRT         If count is <= 0, branch to return
        MOVE.B  (A1)+,D0        Get HEX byte in D0, post-increment A1
        CMP.B   #0,D0           Check if byte is NULL char
        BEQ     DSPSTRT         If byte is NULL char, branch to return
        BSR     HEX2ASCII       Else, get ASCII in D1
        BSR     DSPAX           Display ASCII
        BRA     DSPSTLP         Loop back
DSPSTRT NEG.L   D2              Negate count
        ADD.L   #254,D2         Add 254; effectively 255 - count - null byte
        MOVEM.L (SP)+,D0/D1     Restore D0 and D1
        MOVE.B  D2,D1           Move length to D1
        MOVEM.L (SP)+,D2/A1     Restore D2 and A1
        RTS                     Return to caller

*
* Display offset space: Display space according to offset length
* Input offset length in D2.B
*

DSPOFS  MOVEM.L D0-D2,-(SP)     Push D0-D2 to stack
        * Ensure count is strictly in one byte
        CLR.L   D0
        MOVE.B  D2,D0
        MOVE.L  D0,D2
DSPOFLP DBRA    D2,*+8          Decrement count; if count is > 0, do not branch to return
        BRA     DSPOFRT         If count is <= 0, branch to return
        MOVE.B  #6,D0           Display character
        MOVE.B  #' ',D1         Read space
        TRAP    #15
        BRA     DSPOFLP         Loop back
DSPOFRT MOVEM.L (SP)+,D0-D2     Restore D0-D2
        RTS                     Return to callr

*
* Display operand: Displays operand according to mode and register
* Input mode in D2.B, input reg in D3.B
*

DISPOP  MOVEM.L D0-D2,-(SP)         Push D0-D2 to stack
        MOVE.B  #6,D0               Display character
        MULU.W  #4,D2
        JMP     DMDTBL(PC,D2.W)     Jump to mode
DMDTBL  BRA     DISP0               Dn
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
        JMP     DRGTBL(PC,D3.W)     Jump to reg
DRGTBL  BRA     DISP8               (XXX).W
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
        CMP.B   #0,D2               Test if size is byte
        BNE     *+6                 If !=, skip next line
        MOVE.B  #1,D2               If ==, change byte to word
        MULU.W  #2,D2               Translate size to value
        BSR     DSPHXA              Display address
        ADD.L   D2,A1               Advance A1 by instruction size
        MOVE.L  A1,(IOADDR)         Move A1 to IOADDR
        BRA     DISPD               Branch to return
DISPD   MOVEM.L (SP)+,D0-D2         Restore D0-D2
        RTS                         Return to caller
        
BRBAD   MOVE.B  (IOOPCD),(IOBDCD)   Move OPCODE to BAD OPCODE
        MOVE.B  #$87,(IOOPCD)       Set OPCODE to BAD
        * Clear bad data
        MOVE.B  #$FF,(SMD)
        MOVE.B  #$FF,(SRG)
        MOVE.B  #$FF,(DMD)
        MOVE.B  #$FF,(DRG)
        MOVE.B  #$FF,(IOSIZE)
        
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
        CLR.L   D2
        LEA     OPNAME,A1           Read OP-code
        MOVE.B  (IOOPCD),D0         Get offset
        ADD.L   D0,A1               Add offset
        BSR     DSPSTR              Display string until NULL char and get length in D1.B
        MOVE.B  D1,D2               Store length in D2 to be used as space offset
    
        CMP.B   #$FF,(IOBDCD)       Test if BAD OP code exists
        BEQ     *+52                If it doesn't exist, don't display it
        MOVE.B  #6,D0               Display character
        MOVE.B  #' ',D1             Read space
        TRAP    #15
        MOVE.B  #'(',D1             Read (
        TRAP    #15
        LEA     OPNAME,A1           Read OP-code
        MOVE.B  (IOBDCD),D0         Get offset
        ADD.L   D0,A1               Add offset
        BSR     DSPSTR              Display string until NULL char and get length in D1.B
        ADD.B   D1,D2               Add length to space offset
        MOVE.B  #6,D0               Display character
        MOVE.B  #'?',D1
        TRAP    #15                 Read ?
        MOVE.B  #')',D1             Read )
        TRAP    #15
        ADD.B   #2,D2               Add 2 to space offset to account for ( and )

        LEA     IOOPSZ,A1           Read OP code size
        MOVE.B  #$03,D0             Set size to 3
        CMP.B   #$FF,(IOSIZE)       Test if OP size exists
        BEQ     *+6                 If OP size doesn't exist, skip the next line
        MOVE.B  (IOSIZE),D0         If OP size exists, move it to D0
        MULU.W  #$3,D0              Multiply size by 3 for correct offset
        ADD.L   D0,A1               Add offset
        BSR     DSPSTR              Display string until NULL char and get length in D1.B
        
        ADD.B   D1,D2               Add length to space offset
        NEG.W   D2                  Negate space offset
        ADD.W   #11,D2              Add 11 to space offset; effectively 11 - space offset

        BSR     DSPOFS              Display space offset with tab

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
        ADD.L   #$2,(GBUFF)     Advance buffer

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
DSPHDR  MOVE.B  #11,D0              Clear the screen
        MOVE.W  #$FF00,D1
        TRAP    #15
        LEA     HEADR,A1            Display header
        MOVE.B  #14,D0
        TRAP    #15
        CLR.B   (IOLC)              Reset line counter
        BRA     OP

DONE    LEA     MSSG5,A1            Display end message
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  #9,D0
        TRAP    #15

*--------------------
*   OP
*--------------------

*
* Jump Mask: Use CMPMSK, and jumps to the OP branch if it returns true
* Input CMPMSK inputs, input A0 for OP branch
*

JMPMSK  BSR     CMPMSK          Branch to CMPMSK
        BNE.S   *+18            If the bits did not match, return to caller
        JSR     (A0)            If the bits matched, branch to the OP address
        BNE     *+12            If the OP address was read ybsuccessful, skip the next two lines
        MOVE.L  A1,GBUFF        The buffer was good, move it to GBUFF
        BRA     PRINT           Branch to PRINT     
        MOVE.L  GBUFF,A1        The buffer was bad, restore A1
        RTS                     Return to caller for next instruction

OP      MOVE.L  GBUFF,A0        Set A0 to GBUFF location
        MOVE.L  GBUFF,A1        Set A1 to GBUFF location for sub-routines
        MOVE.B  #0,D2           Set NULL count to 0
        CMP.L   #$FFFFFFFF,(A0) Check for NULL
        BEQ     DONE            If NULL, branch to DONE
        MOVE.W  (A0)+,D0        Transfer word data to D0, post-increment location
        MOVE.W  (A0),D1         Transfer next word data to D1
        MOVE.L   GBUFF,IOADDR   Set memory location for IO
*-----
* 0000
*-----
        * ORI:    00000000XXXXXXXX
        MOVE.W  #%0000000000000000,D2
        MOVE.W  #%1111111100000000,D3
        MOVE.L  #BRORI,A0
        BSR     JMPMSK

        * SUBI:   00000100XXXXXXXX
        MOVE.W  #%0000010000000000,D2
        MOVE.W  #%1111101100000000,D3
        MOVE.L  #BRSUBI,A0
        BSR     JMPMSK

        * ADDI:   00000110XXXXXXXX
        MOVE.W  #%0000011000000000,D2
        MOVE.W  #%1111100100000000,D3
        MOVE.L  #BRADDI,A0
        BSR     JMPMSK

        * BTST:   0000100000XXXXXX
        MOVE.W  #%0000100000000000,D2
        MOVE.W  #%1111011111000000,D3
        MOVE.L  #BRBTST,A0
        BSR     JMPMSK

        * EORI:   00001010XXXXXXXX
        MOVE.W  #%0000101000000000,D2
        MOVE.W  #%1111010100000000,D3
        MOVE.L  #BREORI,A0
        BSR     JMPMSK

        * CMPI:   00001100XXXXXXXX
        MOVE.W  #%0000110000000000,D2
        MOVE.W  #%1111001100000000,D3
        MOVE.L  #BRCMPI,A0
        BSR     JMPMSK
*-----
* 0001
*-----
        * MOVE.B: 0001XXXXXXXXXXXX
        MOVE.W  #%0001000000000000,D2
        MOVE.W  #%1110000000000000,D3
        MOVE.L  #BRMOVE,A0
        BSR     JMPMSK
*-----
* 0010
*-----
        * MOVE.L: 0010XXXXXXXXXXXX
        MOVE.W  #%0010000000000000,D2
        MOVE.W  #%1101000000000000,D3
        BSR     JMPMSK
*-----
* 0011
*-----
        * MOVE.W: 0011XXXXXXXXXXXX 
        MOVE.W  #%0011000000000000,D2
        MOVE.W  #%1100000000000000,D3
        BSR     JMPMSK
*-----
* 0100
*-----
        * NOT:    01000110XXXXXXXX
        MOVE.W  #%0100011000000000,D2
        MOVE.W  #%1011100100000000,D3
        MOVE.L  #BRNOT,A0
        BSR     JMPMSK

        * MULU:   0100110000XXXXXX
        MOVE.W  #%0100110000000000,D2
        MOVE.W  #%1011001111000000,D3
        MOVE.L  #BRMULU,A0
        BSR     JMPMSK

        * DIVS:   0100110001XXXXXX
        MOVE.W  #%0100110001000000,D2
        MOVE.W  #%1011001110000000,D3
        MOVE.L  #BRDIVS,A0
        BSR     JMPMSK

        * MOVEM:  01001X001XXXXXXX
        MOVE.W  #%0100100010000000,D2
        MOVE.W  #%1011001100000000,D3
        MOVE.L  #BRMOVEM,A0
        BSR     JMPMSK

        * RTS:    0100111001110101
        MOVE.W  #%0100111001110101,D2
        MOVE.W  #%1011000110001010,D3
        MOVE.L  #BRRTS,A0
        BSR     JMPMSK

        * JSR:    0100111010XXXXXX
        MOVE.W  #%0100111010000000,D2
        MOVE.W  #%1011000101000000,D3
        MOVE.L  #BRJSR,A0
        BSR     JMPMSK

        * LEA:    0100XXX111XXXXXX
        MOVE.W  #%0100000111000000,D2
        MOVE.W  #%1011000000000000,D3
        MOVE.L  #BRLEA,A0
        BSR     JMPMSK
*-----
* 0101
*-----
        * ADDQ:   0101XXX0XXXXXXXX
        MOVE.W  #%0101000000000000,D2
        MOVE.W  #%1010000100000000,D3
        MOVE.L  #BRADDQ,A0
        BSR     JMPMSK
*-----
* 0110
*-----
        * BCC:    01100000XXXXXXXX
        MOVE.W  #%0110000000000000,D2
        MOVE.W  #%1001111100000000,D3
        MOVE.L  #BRBCC,A0
        BSR     JMPMSK
*-----
* 0111
*-----
        * MOVEQ:  0111XXX0XXXXXXXX
        MOVE.W  #%0111000000000000,D2
        MOVE.W  #%1000000100000000,D3
        MOVE.L  #BRMOVEQ,A0
        BSR     JMPMSK
*-----
* 1000
*-----
        * DIVS:   1000XXX111XXXXXX
        MOVE.W  #%1000000111000000,D2
        MOVE.W  #%0111000000000000,D3
        MOVE.L  #BRDIVS,A0
        BSR     JMPMSK
*-----
* 1001
*-----
        * SUB:    1001XXXXXXXXXXXX
        MOVE.W  #%1001000000000000,D2
        MOVE.W  #%0110000000000000,D3
        MOVE.L  #BRSUB,A0
        BSR     JMPMSK
*-----
* 1010
*-----
*-----
* 1011
*-----
        * CMP:    1011XXXXXXXXXXXX
        MOVE.W  #%1011000000000000,D2
        MOVE.W  #%0100000000000000,D3
        MOVE.L  #BRCMP,A0
        BSR     JMPMSK

        * EOR:    1011XXXXXXXXXXXX
        MOVE.L  #BREOR,A0
        BSR     JMPMSK
*-----
* 1100
*-----
        * AND:    1100XXXXXXXXXXXX
        MOVE.W  #%1100000000000000,D2
        MOVE.W  #%0011000000000000,D3
        MOVE.L  #BRAND,A0
        BSR     JMPMSK

        * MULU:   1100XXX011XXXXXX
        MOVE.W  #%1100000011000000,D2
        MOVE.W  #%0011000100000000,D3
        MOVE.L  #BRMULU,A0
        BSR     JMPMSK
*-----
* 1101
*-----
        * ADD:    1101XXXXXXXXXXXX
        MOVE.W  #%1101000000000000,D2
        MOVE.W  #%0010000000000000,D3
        MOVE.L  #BRADD,A0
        BSR     JMPMSK
*-----
* 1110
*-----
        * ASL/ASR:1110XXXXXXX00XXX
        MOVE.W  #%1110000000000000,D2
        MOVE.W  #%0001000000011000,D3
        MOVE.L  #BRASd,A0
        BSR     JMPMSK

        * LSL/LSR:1110XXXXXXX01XXX
        MOVE.W  #%1110000000001000,D2
        MOVE.W  #%0001000000010000,D3
        MOVE.L  #BRLSd,A0
        BSR     JMPMSK

        * ASL/ASR:1110000X11XXXXXX
        MOVE.W  #%1110000011000000,D2
        MOVE.W  #%0001111000000000,D3
        MOVE.L  #BRASd,A0
        BSR     JMPMSK

        * LSL/LSR:1110001X11XXXXXX
        MOVE.W  #%1110001011000000,D2
        MOVE.W  #%0001110000000000,D3
        MOVE.L  #BRLSd,A0
        BSR     JMPMSK
*-----
* 1111
*-----     
        BRA     BRBAD           No mask matched, branch to BRBAD

*--------------------------
*  Instruction Subroutines
*--------------------------

*
* Test Addressing Modes: Tests last register and mode for valid addressing modes
* Input valid modes in D0.W, output found addressing mode to D1.B, or FF if not found
* Set Z-flag if mode was valid, or clear Z-flag if mode was invalid
*
* D0.W addressing modes (set to 0 for invalid, 1 for valid):
*   0   Dn
*   1   An
*   2   (An)
*   3   (An)+
*   4   -(An)
*   5   (d,An)
*   6   (d,An,Xn)
*   7   (xxx).W
*   8   (xxx).L
*   9   (d,PC)
*   A   (d,PC,Xn)
*   B   #<data>
*
* Modes         %XXXXBA9876543210
M_ALL   EQU     %0000111111111111   All modes
M_DAT	EQU     %0000111111111101   Data modes
M_MEM	EQU     %0000111111111100   Memory modes
M_CTR   EQU     %0000011111100100   Control modes
M_ALT   EQU 	%0000000001111111   Alterable modes
M_MALT  EQU     %0000000111111100   Memory alterable modes
M_DALT  EQU     %0000000111111101   Data alterable modes

TSTAM   MOVE.B  D2,-(SP)        Push D2 to stack
        CLR.L   D1
        MOVE.B  (RGMD),D1       Move REGMOD to D1
        MOVE.B  D1,D2           Copy REGMOD to D2
        LSL.B   #5,D1
        LSR.B   #5,D1           D1 = Mode
        LSR.B   #3,D2           D2 = Register
        CMP.B   #%111,D1        Test mode to 111
        BNE     *+4             If !=, skip next line
        ADD.B   D2,D1           Add register to mode-- effectively creating a 4 bit mode
        BTST    D1,D0           Test mode for validity
        BEQ     *+8             If it is invalid, skip to clear flag
        MOVE.B  (SP)+,D2        If it is valid, restore D2
        BRA     FLAGST          Set flag & return to caller
        MOVE.B  (SP)+,D2        Restore D2
        BRA     FLAGCL          Clear flag & return to caller

*
* Advance Buffer: Advances buffer based on last register and mode
* Input buffer in A1, reg & mode in RGMD, output displacement to DIS
*

ADVBFR  MOVEM.L D1/D2,-(SP)     Push D1 & D2 to the stack
        MOVE.B  #$FF,(DIS)      Set displacement to NULL
        MOVE.B  (RGMD),D1       Move Reg & Mod to D1
        MOVE.L  A1,D2           Copy buffer to D2
        CMP.B   #$07,D1         Test 000 111 = Address (Word)
        BNE.S   *+4             Skip next line
        ADD.L   #$2,A1          Advance buffer by word
        CMP.B   #$0F,D1         Test 001 111 = Address (Long)
        BNE.S   *+4             Skip next line
        ADD.L   #$4,A1          Advance buffer by long
        CMP.B   #$27,D1         Test 100 111 = Immediate (OP code size)
        BEQ     ADVBSZ          If ==, branch to Advance Buffer by Size
        NEG.L   D2              Else, negate original buffer
        ADD.L   A1,D2           Add buffer to get difference
        MOVE.B  D2,(DIS)        Store displacement in DIS
        MOVEM.L (SP)+,D1/D2     Restore D1 & D2
        RTS                     Return to caller

*
* Advance Buffer by Size: Advances buffer based on instruction size
* Input buffer in A1, input size from (IOSIZE), output displacement to DIS
*

ADVBSZ  CMP.B   #$FF,(DIS)      Check if DIS is NULL (255 is odd so displacement should never be FF)
        BEQ     *+6             If it is null, values have already been pushed to the stack, skip the next line
        MOVEM.L D1/D2,-(SP)     Else, push D1 & D2 to the stack
        MOVE.B  (IOSIZE),D1     Read size to D1
        MOVE.L  A1,D2           Copy buffer to D2
        CMP.B   #$1,D0          Test 0 = Byte
        BNE.S   *+4             Skip next line
        ADD.L   #$2,A1          Advance buffer by word (00BB)
        CMP.B   #$1,D1          Test 1 = Word
        BNE.S   *+4             Skip next line
        ADD.L   #$2,A1          Advance buffer by word        
        CMP.B   #$2,D1          Test 2 = Long
        BNE.S   *+4             Skip next line
        ADD.L   #$4,A1          Advance buffer by long
        NEG     D2              Negate original buffer
        ADD.L   A1,D2           Add buffer to get difference
        MOVE.B  D2,(DIS)        Store displacement in DIS
        MOVEM.L (SP)+,D2/D1     Restore D1 and D2
        RTS                     Return to caller

*
* OP Size: Test the standard OP size code
* Inputs size from (DMD), outputs size to IOSIZE, operation to D2.B, correct mode to DMD
* OPM (OP-MODE):  Byte | Word | Long | Operation | D2.B
*                  000 |  001 |  010 |   <ea>,Dn |    0
*                  100 |  101 |  110 |   Dn,<ea> |    1
*                         011 |  111 |   <ea>,An |    2
*

OPSIZE  MOVEM.L D0/D1,-(SP)     Push D0 & D1 to stack
        CLR.W   D1              Ensure displacement will be <= 7
        MOVE.B  (DMD),D1        Get destination mode in D1
        MULU.W  #4,D1           Convert to displacement
        JMP     OPTBL(PC,D1.W)  Jump to OP mode
OPTBL   BRA     OP0             000
        BRA     OP1             001
        BRA     OP2             010
        BRA     OP3             011
        BRA     OP4             100
        BRA     OP5             101
        BRA     OP6             110
        BRA     OP7             111
OP0     MOVE.B  #0,D2           Set OP to 0 for Dn
        MOVE.B  #0,(DMD)        Set mode to Dn
        MOVE.B  #0,D0           Set size to byte
        BRA     OP8             Branch to end
OP1     MOVE.B  #0,D2           Set OP to 0 for Dn
        MOVE.B  #0,(DMD)        Set mode to Dn
        MOVE.B  #1,D0           Set size to word
        BRA     OP8             Branch to end
OP2     MOVE.B  #0,D2           Set OP to 0 for Dn
        MOVE.B  #0,(DMD)        Set mode to Dn
        MOVE.B  #2,D0           Set size to long
        BRA     OP8             Branch to end
OP3     MOVE.B  #2,D2           Set OP to 2 for An
        MOVE.B  #1,(DMD)        Set mode to An
        MOVE.B  #1,D0           Set size to word
        BRA     OP8             Branch to end
OP4     MOVE.B  #1,D2           Set OP to 1 for <ea>
        MOVE.B  #0,(DMD)        Set mode to Dn
        MOVE.B  #0,D0           Set size to byte
        BRA     OP8             Branch to end
OP5     MOVE.B  #1,D2           Set OP to 1 for <ea>
        MOVE.B  #0,(DMD)        Set mode to Dn
        MOVE.B  #1,D0           Set size to word
        BRA     OP8             Branch to end
OP6     MOVE.B  #1,D2           Set OP to 1 for <ea>
        MOVE.B  #0,(DMD)        Set mode to Dn
        MOVE.B  #2,D0           Set size to long
        BRA     OP8             Branch to end
OP7     MOVE.B  #2,D2           Set OP to 2 for An
        MOVE.B  #1,(DMD)        Set mode to An
        MOVE.B  #2,D0           Set size to long
        BRA     OP8             Branch to end
OP8     MOVE.B  D0,(IOSIZE)     Store size in IOSIZE
        MOVEM.L (SP)+,D0/D1     Restore D0 & D1
        RTS                     Return to caller

*
* Extract destination: Extracts destination mode to DMD and destination register to DRG from instruction
* Input instruction from A1, output a combination of reg & mode in RGMD
*

EXDST   MOVEM.L D0-D2,-(SP)     Push D0 - D2 to stack
        MOVE.W  (A1),D0         Move instruction to D0
        MOVE.L  #$1C0,D2        Extract dest mode at 0000000111000000
        BSR     EXTMSK          Get dest mode to D1
        MOVE.B  D1,(DMD)        Move dest mode to DMD
        MOVE.L  #$E00,D2        Extract dest reg at 0000111000000000
        BSR     EXTMSK          Get dest reg to D1
        MOVE.B  D1,(DRG)        Move dest reg to (DRG)

        LSL.B   #3,D1           Shift the reg 3 bits left
        OR.B    (DMD),D1        Add mode after reg
        MOVE.B  D1,(RGMD)       Store D1 in RGMD
        MOVEM.L (SP)+,D0-D2     Restore D0 - D2
        RTS                     Return to caller

*
* Extract source: Extracts source mode to SMD and source register to SRG from instruction
* Inputs instruction from GBUFF, output a combination of reg & mode in RGMD
*

EXSRC   MOVEM.L D0-D2,-(SP)     Push D0 - D2 to stack
        MOVE.W  (A1),D0         Move instruction to D0
        MOVE.L  #$38,D2         Extract src mode at 0000000000111000
        BSR     EXTMSK          Get src mode to D1
        MOVE.B  D1,(SMD)        Move src mode to (OMD)
        MOVE.L  #$7,D2          Extract src reg at 0000000000000111
        BSR     EXTMSK          Get src reg to D1
        MOVE.B  D1,(SRG)        Move src reg to (ORG)
        LSL.B   #3,D1           Shift the reg 3 bits left
        OR.B    (SMD),D1        Add mode after reg
        MOVE.B  D1,(RGMD)       Store D1 in RGMD
        MOVEM.L (SP)+,D0-D2     Restore D0 - D2
        RTS                     Return to caller

* ----------------
* OP Mode Branches
* ----------------
* A1 reserved for tentative good buffer


* ADD: 1101|REG|OPM|EMD|ERG
* Syntax: ADD       <ea>,Dn
*         ADD       Dn,<ea>
* Note: The Dn mode is used when the destination is a data register;
*       the destination <ea> mode is invalid for a data register. 
*       ADDA is used when the destination is an address register.
*       ADDI and ADDQ are used when the source is immediate data.
*       Most assemblers automatically make this distinction.  

BRADD   MOVE.B  #$11,(IOOPCD)   Set OP-code name
        BSR     EXDST           Extract OP mode & register
        BSR     OPSIZE          Translate OP mode from DMD, get operation in D2.B
        * "If the location specified is a destination operand,
        * only memory alterable addressing modes can be used [...]."
        CMP.B   #0,D2           Compare operation to Dn
        BNE.S   *+6             If !=, skip next line
        MOVE.W  #M_MALT,D0      Set memory alterable modes as valid
        * "If the location specified is a source operand,
        * all addressing modes can be used [...]."
        CMP.B   #1,D2           Compare operation to <ea>
        BNE.S   *+6             If !=, skip next line
        MOVE.W  #M_ALL,D0       Set all modes as valid
        * "ADDA is used when the destination is an address register."
        CMP.B   #2,D2           Compare operation to An
        BEQ     BRADDA          If ==, branch to BRADDA

        BSR     EXSRC           Extract EA mode & register
        *BSR     TSTAM           Test modes for validity
        *BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BRA     FLAGST          Return return successful


* ADDA: 1101|REG|OPM|EMD|ERG
* Syntax: ADDA      <ea>,An

BRADDA  MOVE.B  #$15,(IOOPCD)   Set OP-code name
        * "All addressing modes can be used [...]."
        MOVE.W  #M_ALL,D0       Set all modes as valid
        BSR     EXSRC           Extract EA mode & register
        *BSR     TSTAM           Test modes for validity
        *BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BRA     FLAGST          Return successful

* ADDQ: 0101|DAT|0|SZ|EMD|ERG
* Syntax: ADDQ      #<data>,<ea>

BRADDQ  MOVE.B  #$1A,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* ADDI: 000000110|SZ|EMD|ERG
* Syntax: ADDI      #<data>,<ea>

BRADDI  MOVE.B  #$99,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* AND: 1100|REG|OPM|EMD|ERG
* Syntax: AND       <ea>,Dn
*         AND       Dn,<ea>
* Note: The Dn mode is used when the destination is a data register;
*       the destination < ea > mode is invalid for a data register. 
*       Most assemblers use ANDI when the source is immediate data.

BRAND   MOVE.B  #$3B,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* BTST: 0000|REG|100|EMD|ERG (BIT NUMBER DYNAMIC, SPECIFIED IN A REGISTER)
*       0000100000|EMD|ERG  00000000|_BITNUM_ (BIT NUMBER STATIC, SPECIFIED AS IMMEDIATE DATA)
* Syntax: BTST      Dn,<ea>
*         BTST      #<data>,<ea>

BRBTST  MOVE.B  #$58,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* BCC: 0110|COND|_8BTDSP_
* Syntax: BCC       <label>

BRBCC   MOVE.B  #$6B,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBEQ   MOVE.B  #$6F,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful
        
BRBLT   MOVE.B  #$73,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBNE   MOVE.B  #$77,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBHI   MOVE.B  #$7B,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* CMP: 1011|REG|OPM|EMD|ERG
* Syntax: CMP       <ea>,Dn
* Note: CMPA is used when the destination is an address register.
*       CMPI is used when the source is immediate data.
*       CMPM is used for memory-to-memory compares.
*       Most assemblers automatically make the distinction.

BRCMP   MOVE.B  #$5D,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* CMPA: 1011|REG|OPM|EMD|ERG
* Syntax: CMPA      <ea>,An       

BRCMPA  MOVE.B  #$61,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* CMPI: 00001100|SZ|EMD|ERG
* Syntax: CMPI      #<data>,<ea>

BRCMPI  MOVE.B  #$66,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* RTS: 0100111001110101
* Syntax: RTS

BRRTS   MOVE.B  #$83,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* LEA: 0100|REG|111|EMD|ERG
* Syntax: LEA       <ea>,An

BRLEA   MOVE.B  #$37,(IOOPCD)   Set OP-code name
        BSR     EXDST           Extract destination mode & register
        BSR     ADVBFR          Advance the buffer accordingly
        BSR     EXSRC           Extract source mode & register
        BSR     ADVBFR          Advance the buffer accordingly
        BRA     FLAGST          Return successful

* JSR: 0100111010|EMD|ERG
* Syntax: JSR       <ea>

BRJSR   MOVE.B  #$7F,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful
        
* MOVE: 00|SZ|DRG|DMD|SMD|SRG
* Syntax: MOVE      <ea>,<ea>
* Note: Most assemblers use MOVEA when the destination is an address register. 
*       MOVEQ can be used to move an immediate 8-bit value to a data register. 

BRMOVE  MOVE.B  #$00,(IOOPCD)   Set OP-code name
        MOVE.W  (A1),D0         Move instruction to D0
        MOVE.L  #$3000,D2       Extract size at 0011000000000000
        BSR     EXTMSK          Get the size to D1

        MOVE.B  #$FF,D0         Set size to null
        CMP.B   #%01,D1         01 = Byte
        BNE.S   *+6             Branch to next test
        MOVE.B  #$0,D0          Set size to byte
        CMP.B   #%11,D1         11 = Word
        BNE.S   *+6             Branch to next test
        MOVE.B  #$1,D0          Set size to word
        CMP.B   #%10,D1         10 = Long
        BNE.S   *+6             Branch to next test
        MOVE.B  #$2,D0          Set size to long
        CMP.B   #$FF,D0         Test if size was found
        BEQ     FLAGCL          If it was not found, branch to clear flag      
        MOVE.B  D0,(IOSIZE)     If it was found, store size in IOSIZE

        BSR     EXDST           Extract dest EA mode & register
        CMP.B   #1,(DMD)        Compare mode to An
        BEQ     BRMOVEA         If ==, branch to BRMOVEA
        * Dest EA field: "Only data alterable addressing modes can be used [...]."
        MOVE.W  #M_DALT,D0      Set data alterable modes as valid
        *BSR     TSTAM           Test modes for validity
        *BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BSR     EXSRC           Extract source EA mode & register
        * Source EA field: "All addressing modes can be used [...]."
        MOVE.W  #M_ALL,D0       Set all modes as valid
        *BSR     TSTAM           Test modes for validity
        *BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly

        BRA     FLAGST          Return successful


* MOVEA: 00|SZ|DRG|001|SMD|SRG
* Syntax: MOVEA     <ea>,An

BRMOVEA MOVE.B  #$05,(IOOPCD)   Set Op-code name
        CMP.B   #0,(IOSIZE)     Compare size to byte
        BEQ     FLAGCL          If ==, size is not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BSR     EXSRC           Extract source EA mode & register
        * Source EA field: "All addressing modes can be used [...]."
        MOVE.W  #M_ALL,D0       Set all modes as valid (0000011111111111)
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Advance the buffer accordingly
        BRA     FLAGST          Return successful

* MOVEM: 01001|D|001|S|EMD|ERG
* Syntax: MOVEM     <list>,<ea>
*         MOVEM     <ea>,<list>

BRMOVEM MOVE.B  #$0B,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* MOVEQ: 0111|REG|0|__DATA__
* Syntax: MOVEQ     #<data>,Dn

BRMOVEQ MOVE.B  #$8B,(IOOPCD)   Set OP-code name
        BNE     FLAGST          Return unsuccessful

* ASd: 1110000|d|11|EMD|ERG (memory shifts)
*      1110|CRG|d|SZ|i|00|REG (register shifts)
* Syntax: ASd       Dx,Dy
*         ASd       #<data>,Dy
*         ASd       <ea>

BRASd   *MOVE.B  #$50,(IOOPCD)   ASL
        *MOVE.B  #$95,(IOOPCD)   ASR
        BRA     FLAGST          Return successful

* LSd: 1110001|d|11|EMD|ERG (memory shifts)
*      1110|CRG|d|SZ|i|01|REG (register shifts)
* Syntax: LSd       Dx,Dy
*         LSd       #<data>,Dy
*         LSd       <ea>

BRLSd   *MOVE.B  #$91,(IOOPCD)   LSL
        *MOVE.B  #$54,(IOOPCD)   LSR
        BRA     FLAGST          Return successful

* MULU: 1100|REG|011|EMD|ERG (WORD)
*       0100110000|EMD|ERG  0|RDI|0|SZ|0000000|RDH (LONG)
* Syntax: MULU.W    <ea>,Dn    16x16 -> 32
*         MULU.L    <ea>,Dl    32x32 -> 32
*         MULU.L    <ea>,Dh?Dl 32x32 -> 64 

BRMULU  MOVE.B  #$2D,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* DIVS: 1000|REG|111|EMD|ERG (WORD)
*       0100110001|EMD|ERG  0|RDQ|1|S|0000000|RDR (LONG)
* Synax: DIVS.W     <ea>,Dn     32/16 -> 16r ? 16q
*        DIVS.L     <ea>,Dq     32/32 -> 32q
*        DIVS.L     <ea>,Dr:Dq  64/32 -> 32r ? 32q
*        DIVSL.L    <ea>,Dr:Dq 32/32 -> 32r ? 32q

BRDIVS  MOVE.B  #$32,(IOOPCD)   Set OP-code name     
        BRA     FLAGST          Return successful

* EOR: 1011|REG|OPM|EMD|ERG
* Syntax: EOR       Dn,<ea>
* Note: Memory-to-data-register operations are not allowed.
*       Most assemblers use EORI when the source is immediate data.

BREOR   MOVE.B  #$43,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* ORI: 00000000|SZ|EMD|ERG
* Syntax: ORI       #<data>,<ea>

BRORI   MOVE.B  #$3F,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* EORI: 00001010|SZ|EMD|ERG
* Syntax: EORI      #<data>,<ea>

BREORI  MOVE.B  #$47,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* NOT: 01000110|SZ|EMD|ERG
* Syntax:  NOT      <ea>

BRNOT   MOVE.B  #$4C,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* SUB: 1001|REG|OPM|EMD|ERG
* Syntax: SUB       <ea>,Dn
*         SUB       Dn,<ea>
* Note: Most assemblers use SUBA when the destination is an address register
*       and SUBI or SUBQ when the source is immediate data.

BRSUB   MOVE.B  #$1F,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Else, return successful

* SUBA: 1001|REG|OPM|EMD|ERG
* Syntax: SUBA      <ea>,An

BRSUBA  MOVE.B  #$23,(IOOPCD)   Set OP-code name 
        BRA     FLAGST          Else, return successful

* SUBI: 0000|0100|SZ|EMD|ERG
* Syntax: SUBI      #<data>,<ea> 

BRSUBI  MOVE.B  #$28,(IOOPCD)   Set OP-code name
        MOVE.W  (A1),D0         Move instruction to D0
        MOVE.L  #$00C0,D2       Extract size at 0000000011000000
        BSR     EXTMSK          Get the size to D1

        CMP.B   #$FF,D1         Test if size was found
        BEQ     FLAGCL          If it was not found, branch to clear flag      
        MOVE.B  D1,(IOSIZE)     If it was found, store size in IOSIZE

        * Dest EA field: "Only data alterable addressing modes can be used [...]."
        MOVE.W  #M_DALT,D0      Set data alterable modes as valid
        BSR     EXSRC           Extract source EA mode & register 
        MOVE.B  SMD,(DMD)       The EA mode is the Destination mode
        MOVE.B  SRG,(DRG)       The EA reg is the Destination reg
        BSR     ADVBFR          Advance the buffer accordingly
        * SUBI format is SUBI.(size)  #<data>, <ea>
        * manually set the Source mode and source register
        MOVE.B  #$07,(SMD)      Source Mode set to 111
        MOVE.B  #$04,(SRG)      Register Mode set to 100 #<data>
        MOVE.B  SRG,D1          Copy SRG to D1 to manipulate
        LSL.B   #3,D1           Shift the reg 3 bits left
        OR.B    (SMD),D1        Add mode after reg
        MOVE.B  D1,(RGMD)       Store D1 in RGMD
        
        BSR     ADVBFR          Advance the buffer accordingly
        BRA     FLAGST          Else, return successful


* SUBQ: 0101|DAT|1|SZ|EMD|ERG
* Syntax: SUBQ      #<data>,<ea>

        END     START












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

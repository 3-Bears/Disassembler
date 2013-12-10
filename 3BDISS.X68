        INCLUDE "TEST.X68"
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
MNADDR  EQU     $7000       Min address (starting location of test memory)
MXADDR  EQU     $00FFFFFE   Max address (last location for memory - 1 word)

GBUFF   DS.L    1           Pointer to next location in "Good buffer"
SLOC    DS.B    80          Starting location storage
ELOC    DS.B    80          Ending location storage

*-----I/O Memory-----
NGBUFF  DS.L    1           Pointer to next location after the first displayed instruction
IOOPCD  DS.B    1           IO offset value for OPNAME, or FF if none
IOBDCD  DS.B    1           IO offset value for BAD OPNAME, or FF if none
IOSIZE  DS.B    1           IO size for OP code, or FF if none
IOADDR  DS.L    1           IO address value for instruction memory location
IOLC    DS.B    1           IO line counter for screen
IOBC    DS.B    1           IO BAD counter


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
        DC.B    'Bcc',0         107     6B
        DC.B    'BEQ',0         111     6F
        DC.B    'BLT',0         115     73
        DC.B    'BNE',0         119     77
        DC.B    'BHI',0         123     7B
        DC.B    'JSR',0         127     7F
        DC.B    'RTS',0         131     83
        DC.B    'DATA',0        135     87
        DC.B    'MOVEQ',0       140     8C
        DC.B    'LSL',0         146     92
        DC.B    'ASR',0         150     96
        DC.B    'ADDI',0        154     9A
        DC.B    'BRA',0         159     9F
        DC.B    'BSR',0         163     A3
        DC.B    'BCC',0         167     A7
        DC.B    'BCS',0         171     AB
        DC.B    'BVC',0         175     AF
        DC.B    'BVS',0         179     B3
        DC.B    'BPL',0         183     B7
        DC.B    'BMI',0         187     BB
        DC.B    'BGE',0         191     BF
        DC.B    'BGT',0         195     C3
        DC.B    'BLE',0         199     C7
        DC.B    'BLS',0         203     CB
        DC.B    'ANDI',0        207     CF
        DC.B    'SUBQ',0        212     D4
        DC.B    'JMP',0         217     D9
        DC.B    'RTE',0         221     DD
        DC.B    'RTD',0         225     E1
        DC.B    'RTR',0         229     E5
        DC.B    'NOP',0         233     E9
        DC.B    'TRAPV',0       237     ED
        DC.B    'RESET',0       243     F3
        DC.B    'ILLEGAL',0     249     F9


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
*                XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
MSSG0   DC.B    '                        _     _     _     _     _     _ ',CR,LF
        DC.B    '                       (o\---/o)   (o\---/o)   (o\---/o)',CR,LF
        DC.B    '                        | - - |     | ^ ^ |     | . . |',CR,LF
        DC.B    '                       _( (Y)_)_,--.(_(Y)_),--._(_(Y) )_',CR,LF
        DC.B    '                      / /___|_  ".."       ".."  _|___\ \',CR,LF
        DC.B    '                      \_______):     THREE     :(_______/',CR,LF
        DC.B    '                      | |   |        BEARS        |   | |',CR,LF
        DC.B    '                      | |   |    DISASSEMBLER     |   | |',CR,LF
        DC.B    '                      |  \__|__Joey__Terence__Win_|__/  |',CR,LF
        DC.B    '                       \    I  /_  )   |   (  _\  I    /',CR,LF
        DC.B    '                        \____)___)(___/ \___)(___(____/',CR,LF,CR,LF
        DC.B    '     Welcome to 3B Disassembler. The following instructions will guide you',CR,LF
        DC.B    '     through the steps in order to disassemble your code according to your',CR,LF
        DC.B    '     preferences. After which, you may press [BACKSPACE] if you would like',CR,LF
        DC.B    '     to restart the program. You may press 0 at any time, to quit.',CR,LF,CR,LF
        DC.B    ' The following inputs must be entered in HEX format, from 0x7000 to 0x00FFFFFE.',CR,LF,CR,LF,0
MSSG1   DC.B    ' Enter the starting location of the code to be disassembled, or leave it blank',CR,LF
        DC.B    ' for the starting address: 0x',0
MSSG2   DC.B    ' Enter the ending location of the code to be disassembled, or leave it blank',CR,LF
        DC.B    ' for the ending address: 0x',0
MSSG3   DC.B    ' Please note that this program will automatically detect the end of the file if',CR,LF
        DC.B    ' an address is out of range. You may now confirm your inputs before continuing.',CR,LF
        DC.B    '          Continue: [ENTER]      Restart: [BACKSPACE]      Quit: [0]',0
MSSG4   DC.B    'Press [ENTER] for the next page, or [CTRL] + [ENTER] for next line.',0
MSSG5   DC.B    'You have reached the end of the program. Press any key to restart, or 0 to quit.',0
HEADR   DC.B    'Address      OP-Code       Operand',0
ERR0    DC.B    '                     !!! The input address was too small !!!',0
ERR1    DC.B    '                     !!! The input address was too large !!!',0
BLANK   DC.B    '                                                                                ',0
*                XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


START   MOVE.B  #0,IOLC             Set line counter to 0
        MOVE.B  #0,IOBC             Set bad counter to 0
        LEA     MSSG0,A1            Welcome message
        MOVE.B  #14,D0              Display A1 until NULL char
        TRAP    #15
        BRA     PRMPT1              Branch to first prompt

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
* HEX2ASCII: Convert HEX into ASCII.
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

*
* Clear row: Clears the row specified in D1
*

CLRRW   MOVEM.W D0/D1/A1,-(SP)  Push D0, D1, and A1 to stack
        ROL.W   #8,D1           Move row to MSB
        CLR.B   D1              Set column to 0
        ROL.W   #8,D1           Move row to LSB
        MOVE.B  #11,D0          Position cursor at ROW/COL
        TRAP    #15
        LEA     BLANK,A1        Read blank row
        MOVE.B  #14,D0          Display A1 until null
        TRAP    #15
        MOVEM.W (SP)+,D0/D1/A1  Restore D0, D1, and A1
        RTS                     Return to caller

ILL0    LEA     ERR0,A1         Starting location was too small
        MOVE.B  #14,D0
        TRAP    #15
        BRA     PRMPT1          Branch to prompt one
        
ILL1    LEA     ERR1,A1         Starting location was too large
        MOVE.B  #14,D0
        TRAP    #15
        BRA     PRMPT1          Branch to prompt one

ILL2    MOVE.B  #11,D0          Position cursor at COL/ROW
        MOVE.W  #$1D14,D1       Position after input location
        TRAP    #15
        MOVE.L  #MNADDR,D0      Move min address to D0
        BSR     DSPHXL          Display min address to screen
        MOVE.L  #MNADDR,(A1)    Move the min address to SLOC
        BRA     PRMPT2          Branch to the next prompt
        
PRMPT1  MOVE.B  #$14,D1         Set row to $14
        BSR     CLRRW           Clear the row (if existing input is present)
        MOVE.B  #11,D0          Position cursor at COL/ROW
        MOVE.W  #$0013,D1       Position
        TRAP    #15

        LEA     MSSG1,A1        Starting location request message
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     SLOC,A1         Input will be stored in SLOC
        MOVE.B  #2,D0           Input starting location (as string / hex)
        TRAP    #15

        CMP.B   #8,D1           Compare the length of the input to 8
        BGT     ILL1            Branch to ILL1 if > 8
        MOVE.L  (A1),D0         Move input to D0
        CMP.B   #0,D1           Compare the length of the input to 0
        BEQ     ILL2            If the input was null, branch to ILL2
        BSR     ASCII2HEX       Else, convert D0 to HEX in D1
        
        MOVE.L  D1,(A1)         Set SLOC to HEX value
        CMP.L   #$0000F0FF,D1   Compare starting location to 0
        BEQ     HALT            End program if 0
        
        CMP.L   #MNADDR,D1      Compare starting location to min
        BLO     ILL0            Branch to ILL0 if < min
        
        CMP.L   #MXADDR,D1      Compare ending location to max
        BHS     ILL1            Branch to ILL1 if >= max
                
        BRA     PRMPT2          Branch to the next prompt

ILL3    LEA     ERR0,A1         Ending location was too small
        MOVE.B  #14,D0
        TRAP    #15
        BRA     PRMPT2
        
ILL4    LEA     ERR1,A1         Ending location was too big
        MOVE.B  #14,D0
        TRAP    #15

ILL5    MOVE.B  #11,D0          Position cursor at ROW/COL
        MOVE.W  #$1B17,D1       Position after input location
        TRAP    #15
        MOVE.L  #MXADDR,D0      Move max address to D0
        BSR     DSPHXL          Display max address to screen
        MOVE.L  #MXADDR,(A1)    Move the max address to ELOC
        BRA     PRMPTDN         Branch to prompt done
        
PRMPT2  MOVE.B  #$15,D1         Set row to $15
        BSR     CLRRW           Clear the row (if existing error is present)
        MOVE.B  #$17,D1         Set row to $17
        BSR     CLRRW           Clear the row (if existing input is present)
        MOVE.B  #11,D0          Position cursor at COL/ROW
        MOVE.W  #$0016,D1       Position
        TRAP    #15

        LEA     MSSG2,A1        Ending location request message
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     ELOC,A1         Input will be stored in SLOC
        MOVE.B  #2,D0           Input starting location (as string / hex)
        TRAP    #15
        
        CMP.B   #8,D1           Compare the length of the input to 8
        BGT     ILL4            Branch to ILL4 if > 8
        MOVE.L  (A1),D0         Move input to D0
        CMP.B   #0,D1           Compare the length of the input to 0
        BEQ     ILL5            If the input was null, branch to ILL5
        BSR     ASCII2HEX       Else, convert D0 to HEX in D1
        
        MOVE.L  D1,(A1)         Set ELOC to HEX value

        CMP.L   #$0000F0FF,D1   Compare ending location to 0
        BEQ     HALT            End program if 0
        
        CMP.L   #MNADDR,D1      Compare min ending location to min
        BLS     ILL3            Branch to ILL3 if <= min
        
        CMP.L   #MXADDR,D1      Compare ending location to max
        BHI     ILL4            Branch to ILL4 if > max
        
        MOVE.L  (SLOC),D0       Move starting location data to D0
        CMP.L   D0,D1           Compare ending location to starting location
        BLS     ILL3            Branch to ILL3 if <= starting location
        
PRMPTDN MOVE.B  #$18,D1         Set row to $18
        BSR     CLRRW           Clear the row (if existing error is present)
        MOVE.B  #11,D0          Position cursor at COL/ROW
        MOVE.W  #$0019,D1       Position
        TRAP    #15

        LEA     MSSG3,A1        Confirmation message
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.L  (SLOC),(GBUFF)  Store starting location in GBUFF for OP
        MOVE.L  (SLOC),(NGBUFF) Copy to NGBUFF
        BRA     REQKEY          Branch to request key

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
* Display An: Displays An or SP if n == 7
* Input n in D3
*

DSPAn   CMP.B   #7,D3               Compare n to 7
        BEQ     DSPSP               If ==, branch to Display SP
        MOVE.B  #6,D0               Else, display character
        MOVE.B  #'A',D1             Read A
        TRAP    #15
        CLR.L   D0
        MOVE.L  D3,D0               Read reg from D3
        BSR     DSPHXN              Display as hex nibble
        RTS                         Return to caller

DSPSP   MOVE.B  #6,D0               Display character
        MOVE.B  #'S',D1             Read S
        TRAP    #15
        MOVE.B  #'P',D1             Read P
        TRAP    #15
        RTS                         Return to caller

*
* Brief Extension Word: Displays a brief extension word (without displacement)
* Input BEW to D0.B
* X|REG|S|SC|0 -> Xn.S * SC
* X (Index Register Type):
*   0 = Dn
*   1 = An
* S (Index Size):
*   0 = Sign-Extended Word
*   1 = Long Word
* SC (Scale):
*   00 = 1
*   01 = 2
*   10 = 4
*   11 = 8
*

BEXTW   MOVEM.L D0-D3,-(SP)         Push D0-D3 to stack
        MOVE.L  #$70,D2             Extract REG at 01110000
        BSR     EXTMSK              Get REG to D1
        MOVE.B  D1,D3               Move REG to D3
        MOVE.L  #$80,D2	            Extract X at 10000000
        BSR     EXTMSK	            Get X to D1
        MOVE.B  D1,D2               Move MODE to D2
        BSR     DISPOP              Display Xn
        MOVE.L  #8,D2	            Extract S at 00001000
        BSR     EXTMSK	            Get S to D1
        MOVE.B  D1,D3               Move S to D3
        MOVE.L  #6,D2	            Extract SC at 00000110
        BSR     EXTMSK	            Get SC to D1
        MULU.W  #4,D1               Convert D1 to displacement
        JMP     SCTBL(PC,D1.W)      Jump to SC mode
SCTBL   BRA     SC0                 00
        BRA     SC1                 01
        BRA     SC2                 10
        BRA     SC3                 11
SC0     MOVE.B  #1,D2               00 = 1
        BRA     SC4
SC1     MOVE.B  #2,D2               01 = 2
        BRA     SC4
SC2     MOVE.B  #4,D2               10 = 4
        BRA     SC4
SC3     MOVE.B  #8,D2               11 = 8
        BRA     SC4
SC4     MOVE.B  #6,D0               Display character
        MOVE.B  #'.',D1              Read . to D1
        TRAP    #15
        MOVE.B  #'L',D1             Read L to D1 as default
        TST.B   D3                  Test D3 for W
        BNE     *+6                 If !=, skip next line
        MOVE.B  #'W',D1             Else, read W to D1
        TRAP    #15
        MOVE.B  #'*',D1             Read *
        TRAP    #15
        MOVE.B  #3,D0               Display number
        MOVE.B  D2,D1               Read scale
        TRAP    #15
        MOVEM.L (SP)+,D0-D3         Restore D0-D3
        RTS                         Return to caller

* Display displacement in D1.L
DISPDIS MOVEM.L D0-D2,-(SP)         Push D0-D2 to stack
        MOVE.L  D1,D2               Copy displacement to D2
        MOVE.B  #6,D0               Display character
        MOVE.B  #'*',D1             Read *
        TRAP    #15
        CMP.L   #0,D2               Compare data to 0
        BLE     *+8                 If < 0, skip next two lines
        MOVE.B  #'+',D1             Else, read +
        TRAP    #15
        MOVE.B  #3,D0               Display signed number
        MOVE.L  D2,D1               Read data
        TRAP    #15
        MOVE.B  #6,D0               Display character
        MOVE.B  #' ',D1             Read space
        TRAP    #15
        MOVE.B  #'(',D1             Read (
        TRAP    #15
        MOVE.B  #'$',D1             Read $
        TRAP    #15
        MOVE.L  A1,D0               Move instruction address to D0
        ADD.L   D2,D0               Add displacement to address
        CMP.L   #$FFFF,D0           Compare address to greatest word addres
        BGT.S   *+6                 If >, skip next line
        BSR     DSPHXW              Else, display hex word
        CMP.L   #$FFFF,D0           Compare again
        BLE.S   *+6                 If <=, skip next line
        BSR     DSPHXL              Else, display as hex long
        MOVE.B  #6,D0               Display character
        MOVE.B  #')',D1             Read )
        TRAP    #15
        MOVEM.L (SP)+,D0-D2         Restore D0-D2
        RTS                         Return to caller

*
* Display operand: Displays operand according to mode and register
* Input mode in D2.B, input reg in D3.B
*

DISPOP  MOVEM.L D0-D7/A0-A7,-(SP)   Push all registers to stack
        MOVE.B  #6,D0               Display character
        MULU.W  #4,D2
        JMP     DMDTBL(PC,D2.W)     Jump to mode
DMDTBL  BRA     DISPM0              Dn
        BRA     DISPM1              An
        BRA     DISPM2              (An)
        BRA     DISPM3              (An)+
        BRA     DISPM4              -(An)
        BRA     DISPM5              (d,An)
        BRA     DISPM6              (d,An,Xn)
        BRA     DISPM7              (XXX).W/(XXX).L/(d,PC)/(d,PC,Xn)/#data
        BRA     DISPM8              3 BEARS CUSTOM
        BRA     DISPM9              Special (111) next word
* Dn	    	0000 XXXX
DISPM0  MOVE.B  #'D',D1             Read D
        TRAP    #15
        CLR.L   D0
        MOVE.B  D3,D0               Read reg from D3
        BSR     DSPHXN              Display as hex nibble
        BRA     DISPRT              Branch to return
* An		    0001 XXXX
DISPM1  BSR     DSPAn               Display An or SP        
        BRA     DISPRT              Branch to return
* (An)		    0010 XXXX
DISPM2  MOVE.B  #'(',D1             Read (
        TRAP    #15
        BSR     DSPAn               Display An or SP
        MOVE.B  #6,D0               Display character
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPRT              Branch to return
* (An)+		    0011 XXXX
DISPM3  MOVE.B  #'(',D1             Read (
        TRAP    #15
        BSR     DSPAn               Display An or SP
        MOVE.B  #6,D0               Display character
        MOVE.B  #')',D1             Read )
        TRAP    #15
        MOVE.B  #'+',D1             Read +
        TRAP    #15
        BRA     DISPRT              Branch to return
* -(An)		    0100 XXXX
DISPM4  MOVE.B  #'-',D1             Read +
        TRAP    #15
        MOVE.B  #'(',D1             Read (
        TRAP    #15
        BSR     DSPAn               Display An or SP
        MOVE.B  #6,D0               Display character
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPRT              Branch to return
* (d16,An)		0101 XXXX
DISPM5  MOVE.B  #'(',D1             Read (
        TRAP    #15
        MOVE.B  #3,D0               Display signed number
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        MOVE.W  (A1),D1             Read word to D1
        EXT.L   D1                  Extend word to long
        TRAP    #15
        ADD.L   #2,(IOADDR)         Advance IO address by word
        MOVE.B  #6,D0               Display character
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        BSR     DSPAn               Display An or SP
        MOVE.B  #6,D0               Display character
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPRT              Branch to return
* (d8,An,Xn)    0110 XXXX
DISPM6  MOVE.B  #'(',D1             Read (
        TRAP    #15
        MOVE.B  #3,D0               Display signed number
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        MOVE.B  (A1)+,(DIS)         Store byte to displacement (DIS) and post-increment A1
        MOVE.B  (A1),D1             Read next byte to D1 for the actual displacement
        EXT.W   D1                  Extend byte to word
        EXT.L   D1                  Extend word to long
        TRAP    #15
        MOVE.B  #6,D0               Display character
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        BSR     DSPAn               Display An or SP
        MOVE.B  #6,D0               Display character
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        MOVE.B  (DIS),D0            Read (DIS) to D0
        BSR     BEXTW               Display Brief Extension Word
        ADD.L   #2,(IOADDR)         Advance IO address by word
        MOVE.B  #6,D0               Display character
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPRT              Branch to return
* (XXX).W/(XXX).L/(d16,PC)/(d8,PC,Xn)/#data
DISPM7  MULU.W  #4,D3
        JMP     DRGTBL(PC,D3.W)     Jump to reg
DRGTBL  BRA     DISPR0              (XXX).W
        BRA     DISPR1              (XXX).L
        BRA     DISPR2              (d,PC)
        BRA     DISPR3              (d,PC,Xn)
        BRA     DISPR4              #data
* (XXX.W)		0111 0000
DISPR0  MOVE.B  #'$',D1             Read $
        TRAP    #15
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        CLR.L   D2
        MOVE.B  #2,D2               Read word size to D2
        BSR     DSPHXA              Display address
        ADD.L   D2,(IOADDR)         Advance IO address by word
        BRA     DISPRT              Branch to return
* (XXX.L)		0111 0001
DISPR1  MOVE.B  #'$',D1             Read $
        TRAP    #15
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        CLR.L   D2
        MOVE.B  #4,D2               Read long size to D2
        BSR     DSPHXA              Display address
        ADD.L   D2,(IOADDR)         Advance IO address by long
        BRA     DISPRT              Branch to return
* (d16,PC)		0111 0010
DISPR2  MOVE.B  #'(',D1             Read (
        TRAP    #15
        MOVE.B  #3,D0               Display signed number
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        MOVE.W  (A1),D1             Read word to D1
        EXT.L   D1                  Extend word to long
        TRAP    #15
        ADD.L   #2,(IOADDR)         Advance IO address by word
        MOVE.B  #6,D0               Display character
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        MOVE.B  #'P',D1             Read P
        TRAP    #15
        MOVE.B  #'C',D1             Read C
        TRAP    #15
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPRT              
* (d8,PC,Xn)	0111 0011
DISPR3  MOVE.B  #'(',D1             Read (
        TRAP    #15
        MOVE.B  #3,D0               Display signed number
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        MOVE.B  (A1)+,(DIS)         Store byte to displacement (DIS) and post-increment A1
        MOVE.B  (A1),D1             Read next byte to D1 for the actual displacement
        EXT.W   D1                  Extend byte to word
        EXT.L   D1                  Extend word to long
        TRAP    #15
        MOVE.B  #6,D0               Display character
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        MOVE.B  #'P',D1             Read P
        TRAP    #15
        MOVE.B   #'C',D1            Read C
        TRAP    #15
        MOVE.B  #',',D1             Read ,
        TRAP    #15
        MOVE.B  (DIS),D0            Read (DIS) to D0
        BSR     BEXTW               Display Brief Extension Word
        ADD.L   #2,(IOADDR)         Advance IO address by word
        MOVE.B  #6,D0               Display character
        MOVE.B  #')',D1             Read )
        TRAP    #15
        BRA     DISPRT              Branch to return
* #<data>		0111 0100
DISPR4  MOVE.B  #'#',D1             Read #
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
        BRA     DISPRT              Branch to return
* 3 BEARS CUSTOM MODE
* Custom sizes:
*   Q = Quick data
DISPM8  MULU.W  #4,D3
        JMP     D3BTBL(PC,D3.W)     Jump to reg
D3BTBL  BRA     DISPC0              #<1-8>.Q
        BRA     DISPC1              #<data>.Q
        BRA     DISPC2              (DIS).Q
        BRA     DISPC3              (DIS).B
        BRA     DISPC4              (DIS).W
        BRA     DISPC5              (DIS).L
        BRA     DISPC6              (RLM).L
        BRA     DISPC7              (MLR).L
        BRA     DISPC8              #<bit num>.B

* #<1-8>.Q     1000 0000
DISPC0  MOVE.B  #'#',D1             Read #
        TRAP    #15
        CLR.L   D0
        CLR.L   D1
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        MOVE.W  -(A1),D0            Pre-decrement location, get instruction to D0
        MOVE.L  #$0700,D2           Extract data at 000011100000000
        BSR     EXTMSK              Get the data to D1
        TST     D1                  Compare data to 0
        BNE     *+4                 If !=, skip the next line
        MOVE.L  #8,D1               Else, change 0 to 8
        MOVE.B  #3,D0               Read number
        TRAP    #15
        BRA     DISPRT              Branch to return
* #<data>.Q     1000 0001
DISPC1
        BRA     DISPRT              Branch to return
* (DIS).Q       1000 0010
* "1000 BRA -7 *Branch back 7 bytes
*  is acceptable, but:
*  1000 BRA 993 * Branch to address 993
*  is better."
*  3 Bears believes:
*  1000 BRA *-7 ($993)
*  is BEST.
DISPC2  CLR.L   D0
        CLR.L   D1
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        MOVE.W  -(A1),D0            Pre-decrement location, get instruction to D0
        MOVE.L  #$00FF,D2           Extract byte displacement at 0000000011111111
        BSR     EXTMSK              Get the data to D1
        EXT.W   D1                  Extend byte to word
        EXT.L   D1                  Extend word to long
        ADD.L   #2,D1               Add word for instruction to PC
        BSR     DISPDIS             Display displacement
        BRA     DISPRT              Branch to return
        
* (DIS).B       1000 0011
DISPC3  CLR.L   D0
        CLR.L   D1
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        MOVE.W  (A1),D0             Get displacement to D0
        EXT.W   D0                  Extend byte to word
        EXT.L   D0                  Extend word to long
        ADD.L   #2,D0               Add word for data to PC
        SUB.L   #2,A1               Advance A1 by word
        MOVE.L  D0,D1               Move D0 to D1
        BSR     DISPDIS             Display displacement
        BRA     DISPRT              Branch to return
* (DIS).W       1000 0100
DISPC4  CLR.L   D0
        CLR.L   D1
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        MOVE.W  (A1),D0             Get displacement to D0
        EXT.L   D0                  Extend word to long
        ADD.L   #2,D0               Add word for data to PC
        SUB.L   #2,A1               
        MOVE.L  D0,D1               Move D0 to D1
        BSR     DISPDIS             Display displacement
        BRA     DISPRT              Branch to return
* (DIS).L       1000 0101
DISPC5  CLR.L   D0
        CLR.L   D1
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        MOVE.L  (A1),D0             Get displacement to D0
        ADD.L   #4,D0               Add long for data to PC
        SUB.L   #4,A1               
        MOVE.L  D0,D1               Move D0 to D1
        BSR     DISPDIS             Display displacement
        BRA     DISPRT              Branch to return
* (RLM).W       1000 0110
DISPC6  MOVEA.L IOADDR,A1   Point A1 to the instruction address
        CLR.L   D2
        MOVE.W  (A1),D2     Get register list mask to D2
        MOVE.L  #0,D3       Count
        MOVE.B  #'D',D5     D/A
        MOVE.B  #$00,D6     / or - separator (set to null for first 1)
        MOVE.L  #RLMNXT,A0  Next instruction
RLMLP   BTST.L  D3,D2       Check bit at count for 0
        BEQ     RLMADV      If bit was 0, branch to LPADV
        MOVE.B  #6,D0       Else, display character
        MOVE.B  D6,D1       Read separator
        MOVE.B  #'/',D6     Set next default separator to /
        TRAP    #15
        MOVE.B  D5,D1       Read A/D
        TRAP    #15
        MOVE.B  #3,D0       Display number
        MOVE.B  D3,D1       Read count
        TRAP    #15
        MOVE.L  D3,D4       Move bit location to D4
RLMINC  CMP.B   #7,D3       Compare count to 7
        BEQ     *+10        If ==, branch to decrement count
        ADD.B   #1,D3       Else, increment count
        BTST.L  D3,D2       Check next bit at count for 0
        BNE     RLMINC      If bit was not 0, keep incrementing
        SUB.B   #1,D3       Decrement count
        NEG.B   D4          Negate bit location
        ADD.B   D3,D4       Add count to location; effectively, count - location = length
        CMP.B   #1,D4       Compare length to 1
        BLE     *+6         If <=, skip the next line
        MOVE.B  #'-',D6     Else, set separator to -
        CMP.B   #0,D4       Compare length to 0
        BEQ     RLMADV      If ==, branch to instruction
        MOVE.B  #6,D0       Else, display character
        MOVE.B  D6,D1       Read separator
        MOVE.B  #'/',D6     Set next default separator to /
        TRAP    #15
        MOVE.B  D5,D1       Read A/D
        TRAP    #15
        MOVE.B  #3,D0       Display number
        MOVE.B  D3,D1       Read count
        TRAP    #15
RLMADV  ADD.B   #1,D3       Increment count
        CMP.B   #7,D3       Compare count to 7
        BLE     RLMLP       If <=, branch back to loop
        JMP     (A0)        Else, jump to address in A0
RLMNXT  ROL.W   #8,D2       Move A bits to LSB
        MOVE.L  #0,D3       Count
        MOVE.B  #'A',D5     D/A
        MOVE.L  #DISPRT,A0  Next instruction
        BRA     RLMLP       Display A registers
* (MLR).W       1000 0110
DISPC7  MOVEA.L IOADDR,A1   Point A1 to the instruction address
        CLR.L   D2
        MOVE.W  (A1),D2     Get register list mask to D2
        ROL.W   #8,D2       Move D bits to LSB
        MOVE.L  #7,D3       Count
        MOVE.B  #'D',D5     D/A
        MOVE.B  #$00,D6     / or - separator (set to null for first 1)
        MOVE.L  #MLRNXT,A0  Next instruction
MLRLP   BTST.L  D3,D2       Check bit at count for 0
        BEQ     MLRADV      If bit was 0, branch to LPADV
        MOVE.B  #6,D0       Else, display character
        MOVE.B  D6,D1       Read separator
        MOVE.B  #'/',D6     Set next default separator to /
        TRAP    #15
        MOVE.B  D5,D1       Read A/D
        TRAP    #15
        MOVE.B  #3,D0       Display number
        MOVE.B  #7,D1       Read 7
        SUB.B   D3,D1       Subtract count
        TRAP    #15
        MOVE.L  D3,D4       Move bit location to D4
MLRDEC  CMP.B   #0,D3       Compare count to 0
        BEQ     *+10        If ==, branch to decrement count
        SUB.B   #1,D3       Else, decrement count
        BTST.L  D3,D2       Check next bit at count for 0
        BNE     MLRDEC      If bit was not 0, keep decrementing
        ADD.B   #1,D3       Increment count
        SUB.B   D3,D4       Location - count = length
        CMP.B   #1,D4       Compare length to 1
        BLE     *+6         If <=, skip the next line
        MOVE.B  #'-',D6     Else, set separator to -
        CMP.B   #0,D4       Compare length to 0
        BEQ     MLRADV      If ==, branch to instruction
        MOVE.B  #6,D0       Else, display character
        MOVE.B  D6,D1       Read separator
        MOVE.B  #'/',D6     Set next default separator to /
        TRAP    #15
        MOVE.B  D5,D1       Read A/D
        TRAP    #15
        MOVE.B  #3,D0       Display number
        MOVE.B  #7,D1       Read 7
        SUB.B   D3,D1       Subtract count
        TRAP    #15
MLRADV  SUB.B   #1,D3       Decrement count
        CMP.B   #0,D3       Compare count to 0
        BGE     MLRLP       If >=, branch back to loop
        JMP     (A0)        Else, jump to address in A0
MLRNXT  ROL.W   #8,D2       Move A bits to LSB
        MOVE.L  #7,D3       Count
        MOVE.B  #'A',D5     D/A
        MOVE.L  #DISPRT,A0  Next instruction
        BRA     MLRLP       Display A registers
* #<bit num>.B  1000 0111
DISPC8  MOVE.B  #'#',D1             Read #
        TRAP    #15
        CLR.L   D1
        MOVEA.L IOADDR,A1           Point A1 to the instruction address
        MOVE.W  (A1),D1             Read bit number to D1
        MOVE.B  #3,D0               Display number
        TRAP    #15
        BRA     DISPRT              Branch to return
* Special-- next word: The mode was 111, but the value is located in the next word
DISPM9  ADD.L   #2,IOADDR           Advance IOADDR by word
        MOVE.B  #%111,D2            Set mode to 111
        BSR     DISPOP              Display the special mode
        SUB.L   #2,IOADDR           Re-align IOADDR
        BRA     DISPRT              Branch to return
        
DISPRT  MOVEM.L (SP)+,D0-D7/A0-A7   Restore all registers
        RTS                         Return to caller
        

* Display instruction: PRINT sub-routine
DISPINS LEA     OPNAME,A1           Read OP-code
        CLR.L   D0                  Clear D0 for offset
        MOVE.B  (IOOPCD),D0         Get offset
        ADD.L   D0,A1               Add offset
        BSR     DSPSTR              Display string until NULL char and get length in D1.B
        ADD.B   D1,D2               Add length to space offset
        RTS                         Return to PRINT

* Display size: PRINT sub-routine
DISPSZ  LEA     IOOPSZ,A1           Read OP code size
        MOVE.B  #$03,D0             Set size to 3
        CMP.B   #$FF,(IOSIZE)       Test if OP size exists
        BEQ     *+6                 If OP size doesn't exist, skip the next line
        MOVE.B  (IOSIZE),D0         If OP size exists, move it to D0
        MULU.W  #$3,D0              Multiply size by 3 for correct offset
        ADD.L   D0,A1               Add offset
        BSR     DSPSTR              Display string until NULL char and get length in D1.B
        ADD.B   D1,D2               Add length to space offset
        RTS                         Return to PRINT

* Display source: PRINT sub-routine
DISPSRC CLR.W   D2                  Clear mode offset so value <= 7
        CLR.W   D3                  Clear reg offset so value <= 7
        MOVE.B  (SMD),D2            Read source mode to D2
        CMP.B   #$FF,D2             Test if it exists
        BEQ     FLAGCL              If it does not exist, branch to clear flag
        MOVE.B  (SRG),D3            Else, read source reg to D3
        CMP.B   #$FF,D3             Test if it exists
        BEQ     FLAGCL              If it does not exist, branch to clear flag
        BRA     FLAGST              Else, branch to set flag

* Display destination: PRINT sub-routine
DISPDST CLR.W   D2                  Reset mode offset
        CLR.W   D3                  Reset register offset
        MOVE.B  (DMD),D2            Read dest mode to D2
        CMP.B   #$FF,D2             Test if it exists
        BEQ     FLAGCL              If it does not exist, branch to clear flag
        MOVE.B  (DRG),D3            Else, read dest reg to D3
        CMP.B   #$FF,D3             Test if it exists
        BEQ     FLAGCL              If it does not exist, branch to clear flg
        BRA     FLAGST              Else, branch to set flag

* Display address: PRINT sub-routine
DISPADR MOVE.L  (IOADDR),D0         Read memory location
        BSR     DSPHXL              Display as hex long
        MOVE.B  #6,D0               Display character
        MOVE.B  #TB,D1              Read tab
        TRAP    #15
        RTS                         Return to PRINT

* Display bad code: PRINT sub-routine
DISPBD  MOVE.B  #6,D0               Display character
        MOVE.B  #' ',D1             Read space
        TRAP    #15
        MOVE.B  #'(',D1             Read (
        TRAP    #15
        LEA     OPNAME,A1           Read OP-code
        CLR.L   D0                  Clear offset
        MOVE.B  (IOBDCD),D0         Get offset
        ADD.L   D0,A1               Add offset
        BSR     DSPSTR              Display string until NULL char and get length in D1.B
        ADD.B   D1,D2               Add length to space offset
        MOVE.B  #6,D0               Display character
        MOVE.B  #'?',D1
        TRAP    #15                 Read ?
        MOVE.B  #')',D1             Read )
        TRAP    #15
        ADD.B   #4,D2               Add 4 to space offset to account for (, ), ?, and space
        MOVE.B  #$FF,(IOBDCD)       Reset BAD OPCODE
        RTS                         Return to PRINT

* New Line: Displays a new line
NEWLINE MOVEM.W D0/D1,-(SP)         Push D0 and D1 to stack
        MOVE.B  #6,D0               Display character
        MOVE.B  #CR,D1              Read carriage return
        TRAP    #15
        MOVE.B  #LF,D1              Read line feed
        TRAP    #15
        MOVEM.W (SP)+,D0/D1         Restore D0 and D1
        RTS                         Return to caller

* Test Bad: Tests if BAD OPCODE exists, and is not BAD
* Prevents screen from displaying DATA (DATA?) when NO instruction matched
TSTBAD  CMP.B   #$FF,IOBDCD         Check if BAD OPCODE exists
        BEQ     FLAGCL              If it does not exists, branch to clear flag
        CMP.B   #$87,IOBDCD         Else, check if BAD OPCODE is bad
        BEQ     FLAGCL              If ==, branch to clear flag
        BRA     FLAGST              Else, branch to set flag

* Bad: Where naughty instructions are sent to be punished
BRBAD   MOVE.B  (IOOPCD),(IOBDCD)   Move OPCODE to BAD OPCODE
        MOVE.B  #$87,(IOOPCD)       Set OPCODE to BAD
        CMP.B   #4,IOBC             Compare bad counter to 4
        BLT     *+6                 If < 4, skip the next line
        CLR.B   (IOBC)              Else, set counter to 0
        ADD.B   #1,IOBC             Increment bad counter
        * Clear bad data
        MOVE.B  #$FF,(SMD)
        MOVE.B  #$FF,(SRG)
        MOVE.B  #$FF,(DMD)
        MOVE.B  #$FF,(DRG)
        MOVE.B  #$FF,(IOSIZE)
        BRA     PRINT               Branch to PRINT

* PRINT: WHERE ALL OF THE MAGIC HAPPENS!!! :D
PRINT   CMP.B   #$FF,(IOOPCD)       Test if OP code exists
        BEQ     BRBAD               If it does not, display BAD

        CLR.L   D2                  Clear D2 for space offset
        CLR.L   D4                  Set source to false

        CMP.B   #$87,(IOOPCD)       Compare OP code to BAD
        BNE     NOTBAD              If !=, branch to NOTBAD
        CMP.B   #1,IOBC             Else, compare bad counter to 1
        BGT     DISPDAT             If > 1, branch to display raw data
NEWBAD  MOVE.B  #1,(IOBC)           Set bad counter to 1
        BSR     NEWLINE             Else, display new line
        BSR     DISPADR             Display address
        BSR     DISPINS             Display instruction (DATA)
        BSR     TSTBAD              Test if BAD OP code exists
        BNE     *+6                 If it doesn't exist, skip the next line
        BSR     DISPBD              Else, branch to DISPBD and reset IOBDCD
        NEG.W   D2                  Negate space offset
        ADD.W   #14,D2              Add 13 to space offset; effectively 13 - space offset
        BSR     DSPOFS              Display space offset with tab
        ADD.B   #1,IOLC             Increment line counter to counteract DISPDAT
DISPDAT BSR     TSTBAD              Test if BAD OP code exists
        BEQ     NEWBAD              If it exists, branch to NEWBAD to start a new line
        MOVE.L  IOADDR,A1           Else, point A1 to IOADDR
        MOVE.W  (A1),D0             Read data
        BSR     DSPHXW              Display as hex word
        MOVE.B  #6,D0               Display character
        MOVE.B  #' ',D1             Read space
        TRAP    #15
        SUB.B   #1,IOLC             Decrement line counter
        BRA     PRNTFIN             Branch to PRINT finish

NOTBAD  MOVE.B  #0,(IOBC)           Reset bad counter
        BSR     NEWLINE             Display new line
        BSR     DISPADR             Display address
        BSR     DISPINS             Display instruction
        BSR     DISPSZ              Display size
        NEG.W   D2                  Negate space offset
        ADD.W   #14,D2              Add 14 to space offset; effectively 14 - space offset
        BSR     DSPOFS              Display space offset with tab
        ADD.L   #2,(IOADDR)         Move memory location past first word
PRINTS  BSR     DISPSRC             Get source display
        BNE     *+10                If source does not exist, skip the next two lines
        MOVE.B  #1,D4               Else, set source to true
        BSR     DISPOP              Display accordingly
PRINTD  BSR     DISPDST             Get destination display
        BNE     PRNTFIN             If dest does not exists, skip to PRINT finish
        MOVE.B  #6,D0               Display character
        MOVE.B  #',',D1             Read comma
        CMP.B   #1,D4               Test if source was displayed
        BNE     *+2                 If it was not displayed, don't display a comma
        TRAP    #15                 If it was displayed, display a comma
        BSR     DISPOP              Display destination accordingly

PRNTFIN BSR     RESETIO             Reset IO values
        ADD.L   #$2,(GBUFF)         Advance buffer past instruction

        ADD.B   #1,IOLC
        CMP.B   #30,IOLC            Compare #30 to line counter
        BEQ     PAUSE               If ==, branch to PAUSE

        BSR     CHKEND              Check for end of program

        CMP.B   #1,IOLC             Compare #1 to line counter
        BNE     OP                  If !=, branch to OP for next instruction
        MOVE.L  (GBUFF),(NGBUFF)    Else, store GBUFF in NGBUFF

        BRA     OP                  Branch to OP for next instruction

* Reset I/O instruction values
RESETIO MOVE.B  #$FF,(IOOPCD)
        MOVE.B  #$FF,(IOBDCD)
        MOVE.B  #$FF,(IOSIZE)
        MOVE.B  #$FF,(SMD)
        MOVE.B  #$FF,(SRG)
        MOVE.B  #$FF,(DMD)
        MOVE.B  #$FF,(DRG)
        RTS

* Check if the end of the program has been reached
CHKEND  MOVE.L  GBUFF,A0            Set A0 to GBUFF location
        CMPA.L  ELOC,A0             Compare next buffer to ending location
        BGT     DONE                Branch to DONE if > ending location
        RTS                         Else, return to caller

*
* Pause: Halt the instruction display process, and prompt for an action
*

PAUSE   BSR     NEWLINE             Display new line
        LEA     MSSG4,A1            Display keypress prompt
        MOVE.B  #14,D0              Display A1 until null char
        TRAP    #15

*
* Request Key: Request a keyboard input, and do not continue until a valid input was given
*

REQKEY  MOVE.B  #12,D0              Keyboard echo
        MOVE.B  #0,D1               Hidden
        TRAP    #15
        MOVE.B  #5,D0               Request keyboard input
        TRAP    #15
        CMP.B   #$D,D1              Compare input to ENTER
        BEQ     DSPHDR              If ==, branch to DSPHDR
        CMP.B   #$8,D1              Compare input to BACKSPACE
        BEQ     RESTART             If ==, branch to RESTART
        CMP.B   #$30,D1             Compare input to [0]
        BEQ     HALT                If ==, branch to HALT
        CMP.B   #$A,D1              Compare input to CTR + ENTER
        BNE     REQKEY              If !=, loop until a recognized key code was entered
        MOVE.L  (NGBUFF),(GBUFF)    Else, go down one line
        BRA     DSPHDR              Branch to DSPHDR

*
* Display Header: Display the column headers and reset the counters
*

DSPHDR  MOVE.B  #12,D0              Keyboard echo
        MOVE.B  #1,D1               Visible
        TRAP    #15
        MOVE.B  #11,D0              Clear the screen
        MOVE.W  #$FF00,D1
        TRAP    #15
        LEA     HEADR,A1            Display header
        MOVE.B  #14,D0              Display A1 until null char
        TRAP    #15
        CLR.B   (IOLC)              Reset line counter
        CLR.B   (IOBC)              Reset bad counter
        BSR     CHKEND              Check for end of program        
        BRA     OP                  Branch to OP

*
* Done: Display the ending message, and halt the program
*

DONE    BSR     NEWLINE             Display new line
        LEA     MSSG5,A1            Display end message
        MOVE.B  #14,D0              Display A1 until null char
        TRAP    #15
        MOVE.B  #12,D0              Keyboard echo
        MOVE.B  #0,D1               Hidden
        TRAP    #15
        MOVE.B  #5,D0               Request keyboard input
        TRAP    #15
        CMP.B   #$30,D1             Compare input to 0
        BEQ     HALT                If ==, branch to halt

        BRA     RESTART

*
* Halt: Halt the program
*

HALT    MOVE.B  #9,D0               Terminate the program
        TRAP    #15

*
* Restart: Restart the program
*

RESTART MOVE.B  #11,D0              Clear the screen
        MOVE.W  #$FF00,D1
        TRAP    #15
        MOVE.B  #12,D0              Keyboard echo
        MOVE.B  #1,D1               Visible
        TRAP    #15
        CLR.L   (GBUFF)             Reset GBUFF
        CLR.L   (SLOC)              Reset starting location
        CLR.L   (ELOC)              Reset ending location
        MOVEA.L #$01000000,A7       Reset stack pointer
        BRA     START

*--------------------
*   OP
*--------------------

*
* Jump Mask: Use CMPMSK, and jumps to the OP branch if it returns true
* Input CMPMSK inputs, input A0 for OP branch
*

JMPMSK  BSR     CMPMSK              Branch to CMPMSK
        BNE.S   *+18                If the bits did not match, return to caller
        JSR     (A0)                If the bits matched, branch to the OP address
        BNE     *+12                If the OP address was read successful, skip the next two lines
        MOVE.L  A1,(GBUFF)          The buffer was good, move it to GBUFF
        BRA     PRINT               Branch to PRINT     
        MOVE.L  GBUFF,A1            The buffer was bad, restore A1
        RTS                         Return to caller for next instruction

OP      MOVE.L  GBUFF,A0            Set A0 to GBUFF location
        MOVE.L  GBUFF,A1            Set A1 to GBUFF location for sub-routines
        MOVE.B  #0,D2               Set NULL count to 0
        CMP.L   #$FFFFFFFF,(A0)     Check for NULL
        BNE     *+4                 If !==, skip next line
        ADD.B   #1,D2               Else, increment NULL count
        MOVE.W  (A0)+,D0            Transfer word data to D0, post-increment location
        MOVE.W  (A0)+,D1            Transfer next word data to D1, post-increment location
        CMP.L   #$FFFFFFFF,(A0)     Check for NULL
        BNE     *+4                 If !==, skip next line
        ADD.B   #1,D2               Else, increment NULL count
        CMP.B   #2,D2               Compare NULL count to 2
        BEQ     DONE                If ==, branch to DONE
        MOVE.L  GBUFF,IOADDR        Else, Set memory location for IO
*-----
* 0000
*-----
        * ORI:    00000000XXXXXXXX
        MOVE.W  #%0000000000000000,D2
        MOVE.W  #%1111111100000000,D3
        MOVE.L  #BRORI,A0
        BSR     JMPMSK

        * ANDI:   00000010XXXXXXXX
        MOVE.W  #%0000001000000000,D2
        MOVE.W  #%1111110100000000,D3
        MOVE.L  #BRANDI,A0
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

        * BTST:   0000XXX100XXXXXX
        MOVE.W  #%0000000100000000,D2
        MOVE.W  #%1111000011000000,D3
        MOVE.L  #BRBTST,A0
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
        MOVE.L  #BRMOVE,A0
        BSR     JMPMSK
*-----
* 0011
*-----
        * MOVE.W: 0011XXXXXXXXXXXX 
        MOVE.W  #%0011000000000000,D2
        MOVE.W  #%1100000000000000,D3
        MOVE.L  #BRMOVE,A0
        BSR     JMPMSK
*-----
* 0100
*-----
        * NOT:    01000110XXXXXXXX
        MOVE.W  #%0100011000000000,D2
        MOVE.W  #%1011100100000000,D3
        MOVE.L  #BRNOT,A0
        BSR     JMPMSK

        * MOVEM:  01001X001XXXXXXX
        MOVE.W  #%0100100010000000,D2
        MOVE.W  #%1011001100000000,D3
        MOVE.L  #BRMOVEM,A0
        BSR     JMPMSK

        * ILLEGAL:0100101011111100
        MOVE.W  #%0100101011111100,D2
        MOVE.W  #%1011010100000011,D3
        MOVE.L  #BRILLEGAL,A0
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

        * RESET:  0100111001110000
        MOVE.W  #%0100111001110000,D2
        MOVE.W  #%1011000110001111,D3
        MOVE.L  #BRRESET,A0
        BSR     JMPMSK

        * NOP:    0100111001110001
        MOVE.W  #%0100111001110001,D2
        MOVE.W  #%1011000110001110,D3
        MOVE.L  #BRNOP,A0
        BSR     JMPMSK

        * RTE:    0100111001110011
        MOVE.W  #%0100111001110011,D2
        MOVE.W  #%1011000110001100,D3
        MOVE.L  #BRRTE,A0
        BSR     JMPMSK

        * RTD:    0100111001110100
        MOVE.W  #%0100111001110100,D2
        MOVE.W  #%1011000110001011,D3
        MOVE.L  #BRRTD,A0
        BSR     JMPMSK

        * RTS:    0100111001110101
        MOVE.W  #%0100111001110101,D2
        MOVE.W  #%1011000110001010,D3
        MOVE.L  #BRRTS,A0
        BSR     JMPMSK

        * TRAPV:  0100111001110110
        MOVE.W  #%0100111001110110,D2
        MOVE.W  #%1011000110001001,D3
        MOVE.L  #BRTRAPV,A0
        BSR     JMPMSK

        * RTR:    0100111001110111
        MOVE.W  #%0100111001110111,D2
        MOVE.W  #%1011000110001000,D3
        MOVE.L  #BRRTR,A0
        BSR     JMPMSK


        * JSR:    0100111010XXXXXX
        MOVE.W  #%0100111010000000,D2
        MOVE.W  #%1011000101000000,D3
        MOVE.L  #BRJSR,A0
        BSR     JMPMSK
    
        * JMP:    0100111011XXXXXX
        MOVE.W  #%0100111011000000,D2
        MOVE.W  #%1011000100000000,D3
        MOVE.L  #BRJMP,A0
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

        * SUBQ:   0101XXX1XXXXXXXX
        MOVE.W  #%0101000100000000,D2
        MOVE.W  #%1010000000000000,D3
        MOVE.L  #BRSUBQ,A0
        BSR     JMPMSK
*-----
* 0110
*-----
        * Bcc:    0110XXXXXXXXXXXX
        MOVE.W  #%0110000000000000,D2
        MOVE.W  #%1001000000000000,D3
        MOVE.L  #BRBccd,A0
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
        MOVE.W  #%1011000000000000,D2
        MOVE.W  #%0100000000000000,D3
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
        BRA     BRBAD           No mask matched, branch to PRINT

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
        CMP.B   #$07,D1         Test 000 111 = (XXX).W (Word)
        BNE.S   *+4             Skip next line
        ADD.L   #2,A1           Advance buffer by word
        CMP.B   #$0F,D1         Test 001 111 = (XXX).L (Long)
        BNE.S   *+4             Skip next line
        ADD.L   #4,A1           Advance buffer by long
        CMP.B   #$17,D1         Test 010 111 = (d16,PC) (Word)
        BNE.S   *+4             Skip next line
        ADD.L   #2,A1           Advance buffer by word
        CMP.B   #$1F,D1         Test 011 111 = (d8,PC,Xn) (Word)
        BNE.S   *+4             Skip next line
        ADD.L   #2,A1           Advance buffer by word
        CMP.B   #$27,D1         Test 100 111 = Immediate (OP code size)
        BEQ     ADVBSZ          If ==, branch to Advance Buffer by Size
        LSL.B   #5,D1           Else, check the mode...
        LSR.B   #5,D1           D1 = Mode
        CMP.B   #5,D1           Test XXX 101 = (d16,An) (Word)
        BNE     *+4             Skip next line
        ADD.L   #2,A1           Advance buffer by word
        CMP.B   #6,D1           Test XXX 110 = (d8,An,Xn) (Word)
        BNE     *+4             Skip next line
        ADD.L   #2,A1           Advance buffer by word
        NEG.L   D2              Negate original buffer
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
        CMP.B   #0,D1           Test 0 = Byte
        BNE.S   *+4             Skip next line
        ADD.L   #2,A1           Advance buffer by word (00BB)
        CMP.B   #1,D1           Test 1 = Word
        BNE.S   *+4             Skip next line
        ADD.L   #2,A1           Advance buffer by word        
        CMP.B   #2,D1           Test 2 = Long
        BNE.S   *+4             Skip next line
        ADD.L   #4,A1           Advance buffer by long
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
        MOVE.B  (DRG),D1        Move DRG to D1
        LSL.B   #3,D1           Shift the reg 3 bits left
        OR.B    (DMD),D1        Add mode after reg
        MOVE.B  D1,(RGMD)       Store D1 in RGMD
        MOVEM.L (SP)+,D0/D1     Restore D0 & D1
        RTS                     Return to caller

*
* Extract destination: Extracts destination mode to DMD and destination register to DRG from instruction
* Input instruction from GBUFF, output a combination of reg & mode in RGMD
*

EXDST   MOVEM.L D0-D2/A0,-(SP)  Push D0 - D2 and A0 to stack
        MOVE.L  GBUFF,A0        Point A0 to GBUFF
        MOVE.W  (A0),D0         Move instruction to D0
        MOVE.L  #$1C0,D2        Extract dest mode at 0000000111000000
        BSR     EXTMSK          Get dest mode to D1
        MOVE.B  D1,(DMD)        Move dest mode to DMD
        MOVE.L  #$E00,D2        Extract dest reg at 0000111000000000
        BSR     EXTMSK          Get dest reg to D1
        MOVE.B  D1,(DRG)        Move dest reg to (DRG)
        LSL.B   #3,D1           Shift the reg 3 bits left
        OR.B    (DMD),D1        Add mode after reg
        MOVE.B  D1,(RGMD)       Store D1 in RGMD
        MOVEM.L (SP)+,D0-D2/A0  Restore D0 - D2 and A0
        RTS                     Return to caller

*
* Extract source: Extracts source mode to SMD and source register to SRG from instruction
* Inputs instruction from GBUFF, output a combination of reg & mode in RGMD
*

EXSRC   MOVEM.L D0-D2/A0,-(SP)  Push D0 - D2 and A0 to stack
        MOVE.L  GBUFF,A0        Point A0 to GBUFF
        MOVE.W  (A0),D0         Move instruction to D0
        MOVE.L  #$38,D2         Extract src mode at 0000000000111000
        BSR     EXTMSK          Get src mode to D1
        MOVE.B  D1,(SMD)        Move src mode to (OMD)
        MOVE.L  #$7,D2          Extract src reg at 0000000000000111
        BSR     EXTMSK          Get src reg to D1
        MOVE.B  D1,(SRG)        Move src reg to (ORG)
        LSL.B   #3,D1           Shift the reg 3 bits left
        OR.B    (SMD),D1        Add mode after reg
        MOVE.B  D1,(RGMD)       Store D1 in RGMD
        MOVEM.L (SP)+,D0-D2/A0  Restore D0 - D2
        RTS                     Return to caller

* Swap fields: Swaps the destination and source fields
SWAPF   MOVEM.W D0/D1,-(SP)     Push D0 and D1 to stack
        MOVE.B  (DMD),D0        Store DMD in D0
        MOVE.B  (DRG),D1        Store DRG in D1
        MOVE.B  (SMD),(DMD)     Move SMD to DMD
        MOVE.B  (SRG),(DRG)     Move SRG to DRG
        MOVE.B  D0,(SMD)        Move DMD to SMD
        MOVE.B  D1,(SRG)        Move DRG to SRG
        MOVEM.W (SP)+,D0/D1     Restore D0 and D1
        RTS                     Return to caller

* ----------------
* OP Mode Branches
* ----------------
* A1 reserved for tentative good buffer


* ARITHMETIC Q Instruction: XXXX|DAT|X|SZ|EMD|ERG
* Syntax: XXXQ      #<1-8>,<ea>

BRARMQ  MOVE.W  (A1),D0         Move instruction to D0
        MOVE.L  #$00C0,D2       Extract size at 0000000011000000
        BSR     EXTMSK          Get the size to D1

        CMP.B   #%11,D1         Compare size to 11
        BEQ     FLAGCL          If ==, it is invalid, branch to clear flag      
        MOVE.B  D1,(IOSIZE)     Else, store size in IOSIZE

        * dest EA field: "Only alterable addressing modes can be used [...]."
        MOVE.W  #M_ALT,D0       Set alterable modes as valid
        BSR     EXSRC           Extract destination from source location
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        MOVE.B  SMD,(DMD)       Else, move source mode to destination mode
        MOVE.B  SRG,(DRG)       Move source reg to destination reg
        BSR     ADVBFR          Advance the buffer accordingly
        * manually set the source mode and source register
        MOVE.B  #8,(SMD)        Set source mode to 3 BEARS CUSTOM
        MOVE.B  #0,(SRG)        Set reg mode to 0 for #<1-8>
        BRA     FLAGST          Return successful

* IMMEDIATE Instruction: XXXXXXXX|SZ|EMD|ERG
* Syntax: XXXX      #<data>,<ea>
BRIMM   MOVE.W  (A1),D0         Move instruction to D0
        MOVE.L  #$00C0,D2       Extract size at 0000000011000000
        BSR     EXTMSK          Get the size to D1

        CMP.B   #%11,D1         Compare size to 11
        BEQ     FLAGCL          If ==, it is not an immediate instruction, branch to clear flag      
        MOVE.B  D1,(IOSIZE)     Else, store size in IOSIZE

        * dest EA field: "Only data alterable addressing modes can be used [...]."
        MOVE.W  #M_DALT,D0      Set data alterable modes as valid
        BSR     EXSRC           Extract destination from source location
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BSR     SWAPF           Move source to destination
        * manually set the source mode and source register
        MOVE.B  #$07,(SMD)      Set source mode to 111
        MOVE.B  #$04,(SRG)      Set reg mode to 100 for immediate data
        MOVE.B  SRG,D1          Copy SRG to D1 to manipulate
        LSL.B   #3,D1           Shift the reg 3 bits left
        OR.B    (SMD),D1        Add mode after reg 
        MOVE.B  D1,(RGMD)       Store D1 in RGMD
        BSR     ADVBFR          Advance the buffer accordingly
        BRA     FLAGST          Return successful


* ORI: 0000|0000|SZ|EMD|ERG
* Syntax: ORI       #<data>,<ea>

BRORI   MOVE.B  #$3F,(IOOPCD)   Set OP-code name
        BRA     BRIMM           Branch to immediate instruction

* ANDI: 0000|0010|SZ|EMD|ERG
* Syntax: ANDI      #<data>,<ea> 

BRANDI  MOVE.B  #$CF,(IOOPCD)   Set OP-code name
        BRA     BRIMM           Branch to immediate instruction

* SUBI: 0000|0100|SZ|EMD|ERG
* Syntax: SUBI      #<data>,<ea> 

BRSUBI  MOVE.B  #$28,(IOOPCD)   Set OP-code name
        BRA     BRIMM           Branch to immediate instruction

* ADDI: 0000|0110|SZ|EMD|ERG
* Syntax: ADDI      #<data>,<ea>

BRADDI  MOVE.B  #$9A,(IOOPCD)   Set OP-code name
        BRA     BRIMM           Branch to immediate instruction

* EORI: 0000|1010|SZ|EMD|ERG
* Syntax: EORI      #<data>,<ea>

BREORI  MOVE.B  #$47,(IOOPCD)   Set OP-code name
        BRA     BRIMM           Branch to immediate instruction

* CMPI: 0000|1100|SZ|EMD|ERG
* Syntax: CMPI      #<data>,<ea>

BRCMPI  MOVE.B  #$66,(IOOPCD)   Set OP-code name
        BRA     BRIMM           Branch to immediate instruction

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
        * "If the location specified is a source operand,
        * all addressing modes can be used [...]."
        CMP.B   #0,D2           Compare operation to Dn
        BNE.S   *+6             If !=, skip next line
        MOVE.W  #M_ALL,D0       Set all modes as valid
        * "If the location specified is a destination operand,
        * only memory alterable addressing modes can be used [...]."
        CMP.B   #1,D2           Compare operation to <ea>
        BNE.S   *+6             If !=, skip next line
        MOVE.W  #M_MALT,D0      Set memory alterable modes as valid
        * "ADDA is used when the destination is an address register."
        CMP.B   #2,D2           Compare operation to An
        BEQ     BRADDA          If ==, branch to BRADDA
        BSR     ADVBFR          Else, advance the buffer accordingly
        BSR     EXSRC           Extract EA mode & register
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BRA     FLAGST          Return successful


* ADDA: 1101|REG|OPM|EMD|ERG
* Syntax: ADDA      <ea>,An

BRADDA  MOVE.B  #$15,(IOOPCD)   Set OP-code name
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

        * "All addressing modes can be used [...]."
        MOVE.W  #M_ALL,D0       Set all modes as valid
        BSR     EXSRC           Extract EA mode & register
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BRA     FLAGST          Return successful

* ADDQ: 0101|DAT|0|SZ|EMD|ERG
* Syntax: ADDQ      #<1-8>,<ea>

BRADDQ  MOVE.B  #$1A,(IOOPCD)   Set OP-code name
        BRA     BRARMQ          Branch to arithmetic Q instruction

* SUB: 1001|REG|OPM|EMD|ERG
* Syntax: SUB       <ea>,Dn
*         SUB       Dn,<ea>
* Note: Most assemblers use SUBA when the destination is an address register
*       and SUBI or SUBQ when the source is immediate data.

BRSUB   MOVE.B  #$1F,(IOOPCD)   Set OP-code name
        BSR     EXDST           Extract OP mode & register
        BSR     OPSIZE          Translate OP mode from DMD, get operation in D2.B
        * "If the location specified is a source operand,
        * all addressing modes can be used [...]."
        CMP.B   #0,D2           Compare operation to Dn
        BNE.S   *+6             If !=, skip next line
        MOVE.W  #M_ALL,D0       Set all modes as valid
        * "If the location specified is a destination operand,
        * only memory alterable addressing modes can be used [...]."
        CMP.B   #1,D2           Compare operation to <ea>
        BNE.S   *+6             If !=, skip next line
        MOVE.W  #M_MALT,D0      Set memory alterable modes as valid
        * "SUBA is used when the destination is an address register."
        CMP.B   #2,D2           Compare operation to An
        BEQ     BRSUBA          If ==, branch to BRADDA
        BSR     ADVBFR          Else, advance the buffer accordingly
        BSR     EXSRC           Extract EA mode & register
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BRA     FLAGST          Return successful


* SUBA: 1001|REG|OPM|EMD|ERG
* Syntax: SUBA      <ea>,An

BRSUBA  MOVE.B  #$23,(IOOPCD)   Set OP-code name
        CMP.B   #0,(IOSIZE)     Compare size to byte
        BEQ     FLAGCL          If ==, size is not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        * "All addressing modes can be used [...]."
        MOVE.W  #M_ALL,D0       Set all modes as valid
        BSR     EXSRC           Extract EA mode & register
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BRA     FLAGST          Return successful

* SUBQ: 0101|DAT|1|SZ|EMD|ERG
* Syntax: SUBQ      #<1-8>,<ea>
BRSUBQ  MOVE.B  #$D4,(IOOPCD)   Set OP-code name
        BRA     BRARMQ          Branch to arithmetic Q instruction

* AND: 1100|REG|OPM|EMD|ERG
* Syntax: AND       <ea>,Dn
*         AND       Dn,<ea>
* Note: The Dn mode is used when the destination is a data register;
*       the destination < ea > mode is invalid for a data register. 
*       Most assemblers use ANDI when the source is immediate data.

BRAND   MOVE.B  #$3B,(IOOPCD)   Set OP-code name
        BSR     EXDST           Extract OP mode & register
        BSR     OPSIZE          Translate OP mode from DMD, get operation in D2.B
        CMP.B   #2,D2           Compare OP mode to An
        BEQ     FLAGCL          If ==, mode is not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        * "If the location specified is a source operand,
        * only data addressing modes can be used [...]."
        CMP.B   #0,D2           Compare operation to Dn
        BNE.S   *+6             If !=, skip next line
        MOVE.W  #M_DAT,D0       Set data modes as valid
        * "If the location specified is a destination operand,
        * only memory alterable addressing modes can be used [...]."
        CMP.B   #1,D2           Compare operation to <ea>
        BNE.S   *+6             If !=, skip next line
        MOVE.W  #M_MALT,D0      Set memory alterable modes as valid
        BSR     EXSRC           Extract EA mode & register
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BRA     FLAGST          Return successful

* BTST: 0000XXXX00|EMD|ERG
* Syntax: BTST      Dn,<ea>
*         BTST      #<data>,<ea>

BRBTST  MOVE.B  #$58,(IOOPCD)   Set OP-code name
        BSR     EXDST           Extract bits in destination mode & register location
        CMP.B   #0,(DMD)        Compare the mode to STATIC
        BEQ     BRBTSTS         If ==, branch to BTST STATIC
        CMP.B   #4,(DMD)        Compare the mode to DYNAMIC
        BEQ     BRBTSTD         If ==, branch to BTST DYNAMIC
        BRA     FLAGCL          If neither were found, return unsuccessful


* BTST STATIC: 0000100000|EMD|ERG
*              00000000|_BITNUM_
* Syntax: BTST      #<data>,<ea>

BRBTSTS BSR     EXSRC           Extract destination from source location
        * "Only data addressing modes can be used [...]."
        * M68 Manual oddly does not note that #<data> is invalid
        MOVE.W  #$7FD,D0        Set data modes - #<data> as valid %0000111111111101
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance buffer accordingly
        BSR     SWAPF           Swap source to destination
        MOVE.B  #0,(IOSIZE)     Set size to byte
        CMP.B   #0,(DMD)        Compare destination to Dn
        BNE     *+8             If !=, skip the next line
        MOVE.B  #2,(IOSIZE)     Else, set size to long
        ADD.L   #2,A1           Advance buffer for bit num
        MOVE.B  #8,(SMD)        Set source mode to 3 BEARS CUSTOM
        MOVE.B  #8,(SRG)        Set reg mode to 8 for #<bit num>.B
        CMP.B   #%111,(DMD)     Compare destination mode to special
        BNE     FLAGST          If !=, return successful
        MOVE.B  #%1001,(DMD)    Else if ==, set mode to special-- next word
        BRA     FLAGST          Return successful

* BTST DYNAMIC: 0000|REG|100|EMD|ERG
* Syntax: BTST      Dn,<ea>

BRBTSTD BSR     EXSRC           Extract destination from source location
        * "Only data addressing modes can be used [...]."
        MOVE.W  #M_DAT,D0       Set data modes as valid
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance buffer accordingly
        BSR     SWAPF           Swap source to destination
        MOVE.B  #0,(IOSIZE)     Set size to byte
        CMP.B   #0,(DMD)        Compare destination to Dn
        BNE     *+8             If !=, skip the next line
        MOVE.B  #2,(IOSIZE)     Else, set size to long
        MOVE.B  #0,(SMD)        Set source mode to Dn
        BRA     FLAGST          Return successful

* Bcc: 0110|COND|_8BTDSP_
* Syntax: Bcc       <label>
* Branch on...
*  BRA:     0000
*  BSR:     0001
*   HI:     0010
*   LS:     0011
*   CC(HI): 0100
*   CS(LO): 0101
*   NE:     0110
*   EQ:     0111
*   VC:     1000
*   VS:     1001
*   PL:     1010
*   MI:     1011
*   GE:     1100
*   LT:     1101
*   GT:     1110
*   LE:     1111

BRBccd  MOVE.B  #$6B,(IOOPCD)   Set OP-code name
        MOVE.W  (A1),D0         Move instruction to D0
        MOVE.L  #$00FF,D2       Extract displacement at 0000000011111111
        BSR     EXTMSK          Get the displacement to D1
        MOVE.B  #8,(DMD)        Set mode to 3 BEARS CUSTOM
        MOVE.B  #2,(DRG)        Set register to (DISP).Q
        CMP.B   #$00,D1         $00 = 16 bit displacement
        BNE.S   *+10            If !=, skip next two lines
        MOVE.B  #4,(DRG)        Else, Set register to (DISP).W
        ADD.L   #2,A1           Advance buffer by word
        CMP.B   #$FF,D1         $FF = 32 bit displacement
        BNE.S   *+10            If !=, skip next two lines
        MOVE.B  #5,(DRG)        Else, Set register to (DISP).L
        ADD.L   #4,A1           Advance buffer by long
        MOVE.L  #$0F00,D2       Extract condition at  0000111100000000
        CLR.L   D1              Clear D1 for table displacement
        BSR     EXTMSK          Get the condition to D1
        MULU.W  #4,D1           Convert condition to displacement
        JMP     BccTBL(PC,D1)   Jump to condition code branch
BccTBL  BRA     BRBRA
        BRA     BRBSR
        BRA     BRBHI
        BRA     BRBLS
        BRA     BRBCC
        BRA     BRBCS
        BRA     BRBNE
        BRA     BRBEQ
        BRA     BRBVC
        BRA     BRBVS
        BRA     BRBPL
        BRA     BRBMI
        BRA     BRBGE
        BRA     BRBLT
        BRA     BRBGT
        BRA     BRBLE
        BRA     FLAGCL          Return unsuccessful-- this should never happen

BRBEQ   MOVE.B  #$6F,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful
        
BRBLT   MOVE.B  #$73,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBNE   MOVE.B  #$77,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBHI   MOVE.B  #$7B,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBRA   MOVE.B  #$9F,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful
        
BRBSR   MOVE.B  #$A3,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBCC   MOVE.B  #$A7,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBCS   MOVE.B  #$AB,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBVC   MOVE.B  #$AF,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBVS   MOVE.B  #$B3,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful
        
BRBPL   MOVE.B  #$B7,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBMI   MOVE.B  #$BB,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBGE   MOVE.B  #$BF,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBGT   MOVE.B  #$C3,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBLE   MOVE.B  #$C7,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

BRBLS   MOVE.B  #$CB,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* CMP: 1011|REG|OPM|EMD|ERG
* Syntax: CMP       <ea>,Dn
* Note: CMPA is used when the destination is an address register.
*       CMPI is used when the source is immediate data.
*       CMPM is used for memory-to-memory compares.
*       Most assemblers automatically make the distinction.

BRCMP   MOVE.B  #$5D,(IOOPCD)   Set OP-code name
        BSR     EXDST           Extract OP mode & register
        BSR     OPSIZE          Translate OP mode from DMD, get operation in D2.B
        CMP.B   #1,D2           Compare OP mode to <ea>
        BEQ     FLAGCL          If ==, it is invalid, branch to flag clear
        CMP.B   #2,D2           Compare OP mode to An
        BEQ     BRCMPA          If ==, branch to BRCMPA
        BSR     ADVBFR          Else, advance the buffer accordingly
        BSR     EXSRC           Extract source mode & register
        * Source EA field: "All addressing modes can be used [...]."
        MOVE.W  #M_ALL,D0       Set all modes as valid
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
	    BRA     FLAGST          Return successful

* CMPA: 1011|REG|OPM|EMD|ERG
* Syntax: CMPA      <ea>,An

BRCMPA  MOVE.B  #$61,(IOOPCD)   Set OP-code name
        CMP.B   #0,(IOSIZE)     Compare size to byte
        BEQ     FLAGCL          If ==, size is not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BSR     EXSRC           Extract source EA mode & register
        * Source EA field: "All addressing modes can be used [...]."
        MOVE.W  #M_ALL,D0       Set all modes as valid (0000011111111111)
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BRA     FLAGST          Return successful

* EOR: 1011|REG|OPM|EMD|ERG
* Syntax: EOR       Dn,<ea>
* Note: Memory-to-data-register operations are not allowed.
*       Most assemblers use EORI when the source is immediate data.

BREOR   MOVE.B  #$43,(IOOPCD)   Set OP-code name
        BSR     EXDST           Extract OP mode & register
        BSR     OPSIZE          Translate OP mode from DMD, get operation in D2.B
        CMP.B   #1,D2           Compare OP mode to <ea>
        BNE     FLAGCL          If !=, it is invalid, branch to flag clear
        BSR     ADVBFR          Else, advance the buffer accordingly
        BSR     EXSRC           Extract source mode & register
        * Source EA field: "Only data alterable modes can be used [...]."
        MOVE.W  #M_DALT,D0      Set data alterable modes as valid
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BSR     SWAPF           Swap dest & source fields
	    BRA     FLAGST          Return successful

* LEA: 0100|REG|111|EMD|ERG
* Syntax: LEA       <ea>,An

BRLEA   MOVE.B  #$37,(IOOPCD)   Set OP-code name
        BSR     EXDST           Extract destination mode & register
        MOVE.B  #%001,(DMD)     Set destination mode to An
        BSR     EXSRC           Extract source mode & register
        * "Source EA field: "Only control addressing modes can be used [...]."
        MOVE.W  #M_CTR,D0       Set control modes as valid
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BRA     FLAGST          Return successful

* JSR: 0100111010|EMD|ERG
* Syntax: JSR       <ea>

BRJSR   MOVE.B  #$7F,(IOOPCD)   Set OP-code name
        BSR     EXSRC           Extract source mode & register
        * "Source EA field: "Only control addressing modes can be used [...]."
        MOVE.W  #M_CTR,D0       Set control modes as valid
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BRA     FLAGST          Return successful

* JMP: 0100111011|EMD|ERG
* Syntax: JMP       <ea>

BRJMP   MOVE.B  #$D9,(IOOPCD)   Set OP-code name
        BSR     EXSRC           Extract source mode & register
        * "Source EA field: "Only control addressing modes can be used [...]."
        MOVE.W  #M_CTR,D0       Set control modes as valid
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
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
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        BSR     EXSRC           Extract source EA mode & register
        * Source EA field: "All addressing modes can be used [...]."
        MOVE.W  #M_ALL,D0       Set all modes as valid
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
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
        BSR     ADVBFR          Else advance the buffer accordingly
        BRA     FLAGST          Return successful

* MOVEM: 01001|D|001|S|EMD|ERG  REGISTERLISTMASK
* Syntax: MOVEM     <list>,<ea>
*         MOVEM     <ea>,<list>

BRMOVEM MOVE.B  #$0B,(IOOPCD)   Set OP-code name
        MOVE.W  (A1),D0         Move instruction to D0
        MOVE.L  #$40,D2         Extract size at 0000000001000000
        BSR     EXTMSK          Get the size to D1
        ADD.B   #1,D1           Convert size to W/L
        MOVE.B  D1,(IOSIZE)     Store D1 in size
        MOVE.L  #$400,D2        Extract direction at 0000010000000000
        BSR     EXTMSK          Get the direction to D1
        * Direction 0 = Register-to-memory
        * Direction 1 = Memory-to-register
        BSR     EXSRC           Get the EA mode & reg from source location
        * EA field: "For register-to-memory transfers,
        * only control alterable addressing modes
        * or the predecrement addressing mode can be used [...]."
        MOVE.W  #$1F3,D0        Set valid modes for reg-to-mem by default (0000000111110100)
        CMP.B   #0,D1           Compare direction to reg-to-mem
        BEQ.S   *+6             If ==, skip the next line
        * EA field: "For memory-to-register transfers,
        * only control addressing modes
        * or the postincrement addressing mode can be used [...]."
        MOVE.W  #$7EC,D0        Else, Set valid modes for mem-to-reg (0000011111101100)
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else advance the buffer accordingly
        MOVE.B  #8,(DMD)        Set mode to 3 BEARS CUSTOM
        MOVE.B  #6,(DRG)        Set register to (RLM).W by default
        * "For the predecrement mode addresses, the mask correspondence is reversed."
        CMP.B   #%100,(SMD)     Compare source mode to predecrement mode
        BNE.S   *+8             If !=, skip next line
        MOVE.B  #7,(DRG)        Else if ==, set register to (MLR).W
        CMP.B   #%111,(SMD)     Compare source mode to special
        BNE.S   *+8             If !=, skip next line
        MOVE.B  #%1001,(SMD)    Else if ==, set mode to special-- next word
        CMP.B   #0,D1           Compare direction to reg-to-mem again
        BEQ.S   *+6             If ==, skip the next line
        BSR     SWAPF           Else, swap the source and destination
        ADD.L   #2,A1           Advance buffer by word for MLR
        BRA     FLAGST          Return successful

* MOVEQ: 0111|REG|0|__DATA__
* Syntax: MOVEQ     #<data>,Dn

BRMOVEQ MOVE.B  #$8C,(IOOPCD)   Set OP-code name
        BNE     FLAGCL          Return unsuccessful

* ASd: 1110000|d|11|EMD|ERG (memory shifts)
*      1110|CRG|d|SZ|i|00|REG (register shifts)
* Syntax: ASd       Dx,Dy
*         ASd       #<data>,Dy
*         ASd       <ea>

BRASd   *MOVE.B  #$50,(IOOPCD)   ASL
        *MOVE.B  #$96,(IOOPCD)   ASR
        BRA     FLAGCL          Return successful

* LSd: 1110001|d|11|EMD|ERG (memory shifts)
*      1110|CRG|d|SZ|i|01|REG (register shifts)
* Syntax: LSd       Dx,Dy
*         LSd       #<data>,Dy
*         LSd       <ea>

BRLSd   *MOVE.B  #$92,(IOOPCD)   LSL
        *MOVE.B  #$54,(IOOPCD)   LSR
        BRA     FLAGCL          Return successful

* MULU: 1100|REG|011|EMD|ERG (WORD)
*       0100110000|EMD|ERG  0|RDI|0|SZ|0000000|RDH (LONG)
* Syntax: MULU.W    <ea>,Dn    16x16 -> 32
*         MULU.L    <ea>,Dl    32x32 -> 32
*         MULU.L    <ea>,Dh-Dl 32x32 -> 64 

BRMULU  MOVE.B  #$2D,(IOOPCD)   Set OP-code name
        BRA     FLAGCL          Return successful

* DIVS: 1000|REG|111|EMD|ERG (WORD)
*       0100110001|EMD|ERG  0|RDQ|1|S|0000000|RDR (LONG)
* Synax: DIVS.W     <ea>,Dn     32/16 -> 16r ? 16q
*        DIVS.L     <ea>,Dq     32/32 -> 32q
*        DIVS.L     <ea>,Dr:Dq  64/32 -> 32r ? 32q
*        DIVSL.L    <ea>,Dr:Dq 32/32 -> 32r ? 32q

BRDIVS  MOVE.B  #$32,(IOOPCD)   Set OP-code name     
        BRA     FLAGCL          Return successful
 
* NOT: 01000110|SZ|EMD|ERG
* Syntax:  NOT      <ea>

BRNOT   MOVE.B  #$4C,(IOOPCD)   Set OP-code name
        MOVE.W  (A1),D0         Move instruction to D0
        MOVE.L  #$00C0,D2       Extract size at 0000000011000000
        BSR     EXTMSK          Get the size to D1

        CMP.B   #%11,D1         Compare size to 11
        BEQ     FLAGCL          If ==, it is not NOT, branch to clear flag      
        MOVE.B  D1,(IOSIZE)     Else, store size in IOSIZE

        * Dest EA field: "Only data alterable addressing modes can be used [...]."
        MOVE.W  #M_DALT,D0      Set data alterable modes as valid
        BSR     EXSRC           Extract destination from source location
        BSR     TSTAM           Test modes for validity
        BNE     FLAGCL          If not valid, return unsuccessful
        BSR     ADVBFR          Else, advance the buffer accordingly
        * The destination is in the source values, but this is ok because they are
        * only used for display purposes and the order of values.
        BRA     FLAGST          Return successful

* RTS: 0100111001110101
* Syntax: RTS

BRRTS   MOVE.B  #$83,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* RTE: 0100111001110011
* Syntax: RTE

BRRTE   MOVE.B  #$DD,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* RTD: 0100111001110100
* Syntax: RTD

BRRTD   MOVE.B  #$E1,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* RTR: 0100111001110111
* Syntax: RTR

BRRTR   MOVE.B  #$E5,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* ILLEGAL: 0100101011111100
* Syntax: ILLEGAL

BRILLEGAL
        MOVE.B  #$F9,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* NOP: 0100111001110001
* Syntax: NOP

BRNOP   MOVE.B  #$E9,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* RESET: 0100111001110000
* Syntax: RESET

BRRESET MOVE.B  #$F3,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

* TRAPV: 0100111001110110
* Syntax: TRAPV

BRTRAPV MOVE.B  #$ED,(IOOPCD)   Set OP-code name
        BRA     FLAGST          Return successful

        END     START

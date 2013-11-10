*----------------------------------------------------------------------------
* Title      : 3B Disassembler
* Written by : The Three Bears: Joseph Schooley, Nguyen Tong, Terence Calhoun
* Date       : 11/07/2013
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
        
*--------------------
*    Conversion codes
*--------------------

ASCIItoHEX * Convert ASCII into HEX (subtract $30 from each nibble) from D1
        SUB     #$3030,D1       Convert last byte
        SWAP    D1              Swap bytes
        SUB     #$3030,D1       Convert "first" byte
        SWAP    D1              Restore order
        
        * TO DO: Convert 10 - 16 to A - F
        
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
        RTS                     Return to subroutine
        
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
        
        CLR     D1
        MOVE.L  (SLOC),D1
        
        BSR     ASCIItoHEX      Convert D1 to HEX and continue
        
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
        
        CLR     D1
        MOVE.L  (ELOC),D1       Move input to D1
        
        BSR     ASCIItoHEX      Convert D1 to HEX and continue
        
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
        MOVE.L  (A0),D1         Transfer data to memory

LOOP1   CMP.W   ELOC,A0         Compare ending location to location
        BGE     DONE            Branch to DONE if <= to location
        
        * Mask bits to determine OP-code and branch correspondingly
        
		BTST	#%0000010000000000,D1
		BEQ		BRSUBI

		BTST	#%0000000000000000,D1
		BEQ		BRORI

		BTST	#%0000101000000000,D1
		BEQ		BREORI

		BTST	#%0000000100000000,D1
		BEQ		BRBTST

		BTST	#%0000110000000000,D1
		BEQ		BRCMPI

		BTST	#%0001000000000000,D1
		BEQ		BRMOVE

		BTST	#%0010000000010000,D1
		BEQ		BRMOVEA

		BTST	#%0010000000000000,D1
		BEQ		BRMOVE

		BTST	#%0011000000000000,D1
		BEQ		BRMOVE

		BTST	#%0011000001000000,D1
		BEQ		BRMOVEA

		BTST	#%0100100010000000,D1
		BEQ		BRMOVEM

		BTST	#%0100100011000000,D1
		BEQ		BRMOVEM

		BTST	#%0100110010000000,D1
		BEQ		BRMOVEM

		BTST	#%0100110011000000,D1
		BEQ		BRMOVEM

		BTST	#%0100000111000000,D1
		BEQ		BRLEA

		BTST	#%0100110000000000,D1
		BEQ		BRNOT

		BTST	#%0100110010000000,D1
		BEQ		BRNOT

		BTST	#%0100110100000000,D1
		BEQ		BRNOT

		BTST	#%0100111010000000,D1
		BEQ		BRJSR

		BTST	#%0100111001000000,D1
		BEQ		BRRTS

		BTST	#%0101000000000000,D1
		BEQ		BRADDQ

		BTST	#%0110000000000000,D1
		BEQ		BRBCC

		BTST	#%1000000000000000,D1
		BEQ		BRDIVS

		BTST	#%1001000000000000,D1
		BEQ		BRSUB

		BTST	#%1001000001000000,D1
		BEQ		BRSUB

		BTST	#%1001000010000000,D1
		BEQ		BRSUB

		BTST	#%1001000100000000,D1
		BEQ		BRSUB

		BTST	#%1001000101000000,D1
		BEQ		BRSUB

		BTST	#%1001000110000000,D1
		BEQ		BRSUB

		BTST	#%1001000011000000,D1
		BEQ		BRSUBA

		BTST	#%1001000111000000,D1
		BEQ		BRSUBA

		BTST	#%1011000100000000,D1
		BEQ		BREOR

		BTST	#%1011000101000000,D1
		BEQ		BREOR

		BTST	#%1011000110000000,D1
		BEQ		BREOR

		BTST	#%1011000000000000,D1
		BEQ		BRCMP

		BTST	#%1011000001000000,D1
		BEQ		BRCMP

		BTST	#%1011000010000000,D1
		BEQ		BRCMP

		BTST	#%1011000011000000,D1
		BEQ		BRCMPA

		BTST	#%1011000111000000,D1
		BEQ		BRCMPA

		BTST	#%1100000011000000,D1
		BEQ		BRMULU

		BTST	#%1100000000000000,D1
		BEQ		BRAND

		BTST	#%1100000001000000,D1
		BEQ		BRAND

		BTST	#%1100000010000000,D1
		BEQ		BRAND

		BTST	#%1100000100000000,D1
		BEQ		BRAND

		BTST	#%1100000101000000,D1
		BEQ		BRAND

		BTST	#%1100000110000000,D1
		BEQ		BRAND

		BTST	#%1101000000000000,D1
		BEQ		BRADD

		BTST	#%1101000001000000,D1
		BEQ		BRADD

		BTST	#%1101000010000000,D1
		BEQ		BRADD

		BTST	#%1101000100000000,D1
		BEQ		BRADD

		BTST	#%1101000101000000,D1
		BEQ		BRADD

		BTST	#%1101000110000000,D1
		BEQ		BRADD

		BTST	#%1101000011000000,D1
		BEQ		BRADDA

		BTST	#%1101000111000000,D1
		BEQ		BRADDA

		BTST	#%1110000000000000,D1
		BEQ		BRASL

		BTST	#%1110000001000000,D1
		BEQ		BRASL

		BTST	#%1110000010000000,D1
		BEQ		BRASL

		BTST	#%1110000000001000,D1
		BEQ		BRLSR

		BTST	#%1110000001001000,D1
		BEQ		BRLSR

		BTST	#%1110000010001000,D1
		BEQ		BRLSR
		
		BRA     BAD                 No mask matched, branch to BAD

INCREM  MOVE.L  (A0)+,D1            Post-Increment location to memory
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
BRRTS	BRA		INCREM
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

EA
        * Do the stuff

        BRA     DONE
        
        END     START

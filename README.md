#A Disassembler for the Motorola MC68000 Microprocessor

##Group

###The Three Bears

* I/O: Nguyen Tong:
 
 * Handles all inputs from the user and displays to the screen
 
* OP: Joseph Schooley:
 
 * Handles decoding the OP-Codes and passing EA information to EA person
 
* EA: Terence Calhoun:
 
 * Decodes Effective Addresses
 
##Program

###General Program Flow

1. I/O person prompts user for a starting and ending address in memory.
2. User enters starting and ending addresses for region of memory to be disassembled.
3. I/O person checks for errors and if address are correct, prepares display buffer and sends address in memory to OP-Code person.
4. Op-code person can either decode word to legitimate instruction or cannot:

 * If word in memory cannot be decoded to legitimate instruction, I/O person writes to screen ```XXXXXXXX    DATA   YYYY``` where ```XXXXXXXX``` is the memory address of the word and ```YYYY``` is the hex value of the word.
 * If it can be decoded then it is prepared for display and the EA information is passed to the EA person.

5. EA person decodes EA field(s) and:

 * If EA cannot be decoded, signals this back, or
 * Prepares operands for display.

6. Once the instruction is displayed, the process repeats itself.

###Parameter Passing

* A parameters:
 * Pointer to memory to decode
 * Pointer to next available space in “Good buffer”
 * Good/bad flag

* B parameters:
 * Memory pointer to next word after the op-code word
 * 6 bits from EA field of op-code word
 * Pointer to next available space in “Good buffer”
 * Good/bad flag

* C Parameters:
 * Memory pointer to next word after the EA word
 * Pointer to next available space in “Good buffer”
 * Good/bad flag

* D Parameters:
 * Memory pointer to next op-code word
 * Good/bad flag

###Specification

1. Write an inverse assembler (disassembler) that will convert a memory image of instructions and data back to 68000 assembly language and output the disassembled code to the display. You will not be required to disassemble all of the instructions and addressing modes. The list of instructions and addressing modes is given at the end of this project description. Note that I'm not going to fill the memory with garbage, I will write the test program and then assemble it as I would any program.
2. If you want to see how a disassembler works, just take one of your homework problems and load it in memory at address $1000. Then open a memory window and see the code in memory. You can also view it as disassembled code in the simulator.
3. DO NOT USE THE TRAP 60 FACILITY OF THE SIMULATOR. You must completely develop your own disassembler algorithm. If I suspect that you used TRAP 60 I will use a search tool that I designed to scan your source code for the TRAP 60 calls. You may only use the I/O Trap functions up through 14. Trap task 15 and higher may not be used. Note that you can call TRAP #15, for I/O. But you cannot use trap task #15. That is, you cannot call, MOVE.B #15, D0, TRAP #15.
4. Your program should be written from the start in 68000 assembly language. Do not write it in C or C++ and then cross-compile it to 68000 code. It is really easy to tell when you've written it in C and it probably won't save you very much time. When you are working at the bit level C is just structured assembly language (or so they say).
5. Your program should be ORG'ed at $1000.
6. At startup, the program should display whatever welcome messages you want to display and then prompt the user for the starting location  and the ending location of the code to be disassembled. The program should scan the memory region and output the memory addresses of the instructions and the assembly language instructions contained in that region to the display. You should be able to actually disassemble your own program to the display!
7. The display should show one screen of data at a time, hitting the ENTER key should display the next screen of information.
8. The program should be able to realize when it has an illegal instruction ( i.e, data ), and be able to deal with it until it can find instructions again to decode. Instructions that cannot be decoded, either because they do not disassemble as op codes or because you aren't able to decode them should be displayed as ```1000    DATA    $WXYZ``` where ```$WXYZ``` is the hexadecimal number that couldn't be decoded. Your program should not crash because it can't decode an instruction. Remember, it is perfectly legal to have data and instructions interspersed, so it is very possible that you will hit data, and not an instruction.
9. Address displacements or offsets should be properly displayed as positive or negative numbers, but a better grade will be achieved if you actually calculate the address of the branch and display that value. For example:

    ```1000          BRA    -7            *Branch back 7 bytes```
    
    is acceptable, but:
    
    ```1000          BRA    993         * Branch to address 993```
    
    is better.

10. You should do a line by line disassembly, displaying the following columns:

    ```a- Memory location            b- Op-code            c- Operand```
    
11. When it completes the disassembly, the program should prompt the user to disassemble another memory image, or prompt the user to quit.

##Required Code

###Required OP Instructions

- [] MOVE, MOVEA, MOVEM
- [] ADD, ADDA,  ADDQ
- [] SUB, SUBA, SUBI
- [] MULU, DIVS
- [] LEA
- [] AND, ORI
- [] EOR,EORI
- [] NOT
- [] ASL,LSR
- [] BTST
- [] CMP, CMPA,CMPI
- [] Bcc (BEQ, BLT, BNE, BHI)
- [] JSR, RTS

###Required Effective Addressing Modes

- [] Data Register Direct
- [] Address Register Direct
- [] Address Register Indirect
- [] Immediate Data
- [] Address Register Indirect with Post-incrementing
- [] Address Register Indirect with Pre-decrementing
- [] Absolute Long Address
- [] Absolute Word Address

##Goals

* Level 1:
 - [] Program should assemble without errors
 - [] All deliverables are handed in
 - [] A subset of the instructions and addressing modes works properly
 - [] Program doesn't crash on execution
* Level 2:
 - [] 80% of the instructions disassemble properly
 - [] Good structure for code
 - [] Re-synchronization to instruction disassembly from data space is not achieved
* Level 3:
 - [] 90% of the assigned instructions and  address modes are properly decoded
 - [] Well-structured assembly code
 - [] Well-documented test plan and testing
 - [] Efficient use of instructions, addressing modes
 - [] Re-synchronization to instruction disassembly from data space is achieved
* Level 4:
 - [] All assigned instructions and addressing modes are  properly decoded
 - [] Complete bounds checking (can't be broken)
 - [] Superior human interface
 - [] All deliverables demonstrate well above average expectations
 - [] Tight coding, creative use of addressing modes

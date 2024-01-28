; A simple flashing LED test program for the RetroDuino-8085
; The 2 LEDs toggle alternately through a simple loop
;
; This simple code is loaded using MON85. Note that although MON85 resides in
; ROM starting at address 0x0000, MON85 can actually write to the RAM at address
; 0x0000. Any attempt to read from address 0x0000 by MON85 will result in a ROM
; read, not a RAM read.
;
; To run this code, load the HEX file as normal using MON85 and then execute 
; the special bit of code at address 0xFF00 using "g FF00".
; 

; Define the locations of the registers in the 65C22 VIA in I/O space
VIABASE EQU 040H
PORTA   EQU VIABASE+1
PORTB   EQU VIABASE+0
DDRA    EQU VIABASE+3
DDRB    EQU VIABASE+2

;-------------------------------------------------------------------------
; This is the JMP instruction at address 0x0000 that jumps to our code.
; It will be placed in RAM at address 0x0000 by MON85.
;-------------------------------------------------------------------------
    .ORG    0000H
    JMP     START

;-------------------------------------------------------------------------
; Here's the actual flashing LED test code - also residing in RAM at
; address 0x0100.
;-------------------------------------------------------------------------
    .ORG    0100H
START:
; configure the VIA port A so that PA2 & PA3 are outputs
    MVI A,0x0C
    OUT DDRA
    
; turn on LED D3 (PA3)
LOOP:
    MVI A,0x08
    OUT PORTA
    
    LXI B,0
L1:
    DCR C       ; decrement C
    JNZ L1
    DCR B       ; decrement B
    JNZ L1
    
    MVI A,0x04  ; toggle the LEDs
    OUT PORTA
    LXI B,0
L2:
    DCR C       ; decrement C
    JNZ L2
    DCR B       ; decrement B
    JNZ L2

    JMP LOOP

    
    
; A simple flashing LED test program for the RetroDuino-8085
; The 2 LEDs toggle alternately through a simple loop
;

; Define the locations of the registers in the 65C22 VIA in I/O space
VIABASE EQU 040H
PORTA   EQU VIABASE+1
PORTB   EQU VIABASE+0
DDRA    EQU VIABASE+3
DDRB    EQU VIABASE+2

    .ORG    5000H
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
    
/* Simple Text I/O for RetroDuino-8085 using z88dk
 *
 * Designed to be loaded via MON85 and assumes that the UART
 * is already configured.
 *
 * Guidance: https://github.com/z88dk/z88dk/wiki/Classic--Homebrew
 */
 
#include <stdio.h>
#include "sys/hardware.h"

void bigDelay( void );

uint16_t t1 = 0;

int main()
{
    printf("Hello from z88dk!\n");

	pinDir( LED_BUILTIN1, OUTPUT );
	pinWrite( LED_BUILTIN1, 0 );

	t1 = millis();
	printf("T = %u\n", t1);
	while( 1 ) {
		for (uint16_t i=0;i<500; i++) bigDelay();
		t1 = millis();
		printf("T = %u\n", t1);
	}
}

void bigDelay( void )
{
__asm

    mvi     a,$00
delay:
    nop
    nop
    dcr     a
    jnz     delay
	
__endasm
}

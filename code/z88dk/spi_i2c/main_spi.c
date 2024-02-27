/* Simple Text I/O for RetroDuino-8085 using z88dk
 *
 * Designed to be loaded via MON85 and assumes that the UART
 * is already configured.
 *
 * Guidance: https://github.com/z88dk/z88dk/wiki/Classic--Homebrew
 */
 
#include <stdio.h>
#include "sys/hardware.h"

#define SS_PIN	10

void bigDelay( void );

uint8_t toggle = 0;
uint8_t temp;

int main()
{
    printf("Hello from z88dk!\n");

	pinDir( LED_BUILTIN1, OUTPUT );
	pinWrite( LED_BUILTIN1, 0 );
	
	spiSetup();
	pinDir( SS_PIN, OUTPUT );
	pinWrite( SS_PIN , 1 );
	
    while ( 1 ) {
        int c = getchar();
        printf("<%c>=%d  : ", c,c);

		pinWrite( SS_PIN, 0 );
		spiWrite( c );
		pinWrite( SS_PIN, 1 );
		
		bigDelay();

		pinWrite( SS_PIN, 0 );
		temp = spiRead();
		pinWrite( SS_PIN, 1 );

		bigDelay();

		pinWrite( SS_PIN, 0 );
		temp = spiTransfer( c );
		pinWrite( SS_PIN, 1 );

		printf("%02x\n", temp);
		
		toggle++;
		if (( toggle & 0x01 ) == 0) {
			pinWrite( LED_BUILTIN1, 0 );
		} else {
			pinWrite( LED_BUILTIN1, 1 );
		}
    }
}

void bigDelay( void )
{
__asm

    mvi     a,$00       ; silly delay to let port bits settle
delay:
    nop
    nop
    dcr     a
    jnz     delay
	
__endasm
}

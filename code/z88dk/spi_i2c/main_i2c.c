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

uint8_t toggle = 0;
uint8_t temp[10];
uint8_t v1 = 0;
uint8_t v2 = 0;

int main()
{
    printf("Hello from z88dk!\n");

	pinDir( LED_BUILTIN1, OUTPUT );
	pinWrite( LED_BUILTIN1, 0 );
	
	i2cSetup();
	
    while ( 1 ) {
        int c = getchar();
        printf("Writing 0xAA & 0x55 to RTC RAM at address 0x10\n");

		temp[0] = i2cStart( ( 0x68 << 1 ) | 0x00 );
		temp[1] = i2cWriteByte( 0x10 );
		temp[2] = i2cWriteByte( 0xAA );
		temp[3] = i2cWriteByte( 0x55 );
		i2cStop();

		printf("ACK / NACK values were: ");
		for( uint8_t i=0; i<4; i++) {
			printf("%02X ", temp[i]);
		}
		printf("\n");
		
        printf("Now setting read back pointer to RTC RAM at address 0x10\n");
		/* write out the address to read from */
		temp[0] = i2cStart( ( 0x68 << 1 ) | 0x00 );
		temp[1] = i2cWriteByte( 0x10 );
		i2cStop();
		printf("ACK / NACK values were: %02X %02X\n", temp[0], temp[1] );

        printf("Now reading back 2 bytes from RTC RAM at address 0x10\n");
		temp[0] = i2cStart( ( 0x68 << 1 ) | 0x01 );
		temp[1] = i2cReadByte( 0 );
		temp[2] = i2cReadByte( 1 );
		i2cStop();

		printf("ACK / NACK value for receive was: %02X\n", temp[0]);
		printf("Received bytes were: %02X & %02X\n", temp[1], temp[2]);
			
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

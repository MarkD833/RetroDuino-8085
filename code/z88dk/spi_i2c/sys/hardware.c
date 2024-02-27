
#include <stdint.h>
#include "common.h"
#include "hardware.h"

#define UART_BASE_ADDR	0x00
#define VIA_BASE_ADDR	0x40
#define ADC_BASE_ADDR	0x80


/******************************************************************************
ADC0844 Analogue to Digital Converter
******************************************************************************/
__sfr __at ADC_BASE_ADDR ADC_REG;	// single register of the ADC_BASE


/******************************************************************************
W65C22S Versatile Interface Adapter
******************************************************************************/
__sfr __at VIA_BASE_ADDR+0x00 VIA_PORTB;		// Port B input/output register
__sfr __at VIA_BASE_ADDR+0x01 VIA_PORTA;		// Port A input/output register
__sfr __at VIA_BASE_ADDR+0x02 VIA_DDRB;			// Port B data direction register
__sfr __at VIA_BASE_ADDR+0x03 VIA_DDRA;			// Port A data direction register
__sfr __at VIA_BASE_ADDR+0x04 VIA_T1C_LOW;		// Timer 1 counter low byte
__sfr __at VIA_BASE_ADDR+0x05 VIA_T1C_HIGH;		// Timer 1 counter high byte
__sfr __at VIA_BASE_ADDR+0x06 VIA_T1L_LOW;		// Timer 1 latch low byte
__sfr __at VIA_BASE_ADDR+0x07 VIA_T1L_HIGH;		// Timer 1 latch high byte
__sfr __at VIA_BASE_ADDR+0x08 VIA_T2C_LOW;		// Timer 2 counter low byte
__sfr __at VIA_BASE_ADDR+0x09 VIA_T2C_HIGH;		// Timer 2 counter high byte
__sfr __at VIA_BASE_ADDR+0x0A VIA_SR;			// Shift register
__sfr __at VIA_BASE_ADDR+0x0B VIA_ACR;			// Aux control register
__sfr __at VIA_BASE_ADDR+0x0C VIA_PCR;			// Peripheral control register
__sfr __at VIA_BASE_ADDR+0x0D VIA_IFR;			// Interrupt flag register
__sfr __at VIA_BASE_ADDR+0x0E VIA_IER;			// Interrupt enable register
__sfr __at VIA_BASE_ADDR+0x0F VIA_ALTPORTA;		// Port A alternate input/output register


/******************************************************************************
SCC2691 Single Channel UART
******************************************************************************/
__sfr __at UART_BASE_ADDR+0x00 UART_MODE;		// R/W : Mode Register #1 & #2
__sfr __at UART_BASE_ADDR+0x01 UART_STATUS;		//  R  : Status Register
__sfr __at UART_BASE_ADDR+0x01 UART_CLKSEL;		//  W  : Clock Select Register
__sfr __at UART_BASE_ADDR+0x02 UART_BRGTEST;	//  R  : Baud Rate Generator Test
__sfr __at UART_BASE_ADDR+0x02 UART_COMMAND;	//  W  : Command Register
__sfr __at UART_BASE_ADDR+0x03 UART_RXDATA;		//  R  : Rx Data Register
__sfr __at UART_BASE_ADDR+0x03 UART_TXDATA;		//  W  : Tx Data Register
__sfr __at UART_BASE_ADDR+0x04 UART_1X16XTEST;	//  R  : 1x/16x Test Register
__sfr __at UART_BASE_ADDR+0x04 UART_AUXCTRL;	//  W  : Aux Control Register
__sfr __at UART_BASE_ADDR+0x05 UART_INTSTAT;	//  R  : Interrupt Status Register
__sfr __at UART_BASE_ADDR+0x05 UART_INTMASK;	//  W  : Interrupt Mask Register
__sfr __at UART_BASE_ADDR+0x06 UART_CTHIGH;		// R/W : Counter/Timer bits 8..15 Register
__sfr __at UART_BASE_ADDR+0x07 UART_CTLOW;		// R/W : Counter/Timer bits 0..7 Register


/******************************************************************************
    #     #     #     #     #        #######   #####   #     #  ####### 
   # #    ##    #    # #    #        #     #  #     #  #     #  #       
  #   #   # #   #   #   #   #        #     #  #        #     #  #       
 #     #  #  #  #  #     #  #        #     #  #  ####  #     #  #####   
 #######  #   # #  #######  #        #     #  #     #  #     #  #       
 #     #  #    ##  #     #  #        #     #  #     #  #     #  #       
 #     #  #     #  #     #  #######  #######   #####    #####   ####### 
*******************************************************************************
* ADC0844 Analogue to Digital Converter
*******************************************************************************
*/

/* adcRead - read the result of a previously started conversion
 */
uint8_t adcRead( void )
{
	return ADC_REG;
}

/* adcStartConversion - initiate an A2D measuring cycle
 */
void adcStartConversion( uint8_t ch )
{
	if (ch > 3) return;

	ADC_REG = ch | 0x40;
}

/******************************************************************************
 ######   ###   #####   ###  #######     #     #       
 #     #   #   #     #   #      #       # #    #       
 #     #   #   #         #      #      #   #   #       
 #     #   #   #  ####   #      #     #     #  #       
 #     #   #   #     #   #      #     #######  #       
 #     #   #   #     #   #      #     #     #  #       
 ######   ###   #####   ###     #     #     #  ####### 
*******************************************************************************
* W65C22S Versatile Interface Adapter
*******************************************************************************
*/

/* Pin map shows which VIA port and mask is needed to set/clear a header pin.
 * It also shows which data direction register is required to set a header pin direction.
 *
 * Port value:
 * 1st byte is added to VIA_PORTB to get the actual port address
 * 2nd byte is used to set/clear the port pin
 *
 * Direction: 
 * 1st byte is added to VIA_DDRB to get the actual port address
 * 2nd byte is used to set/clear the port direction
 */
#define MAXPINS 16
static uint8_t pinMap[ MAXPINS ][2] = {
	{1, 0x04}, {1, 0x08}, {1, 0x10}, {1, 0x20},    /* pins  0 .. 3  */
	{0, 0x80}, {0, 0x40}, {1, 0x40}, {1, 0x80},    /* pins  4 .. 7  */
	{0, 0x01}, {0, 0x02}, {0, 0x04}, {0, 0x08},    /* pins  8 .. 11 */
   	{0, 0x10}, {0, 0x20}, {1, 0x02}, {1, 0x01}     /* pins 12 .. 15 */
};

/******************************************************************************
* pinRead - return the state of a pin
* ----------------------------------------------------------------------------
* pin    : pin number from 0 to 15
* return : 0=>LOW, 1=>HIGH
******************************************************************************/
uint8_t pinRead(uint8_t pin)
{
	if (pin >= MAXPINS) return;
}

/******************************************************************************
* pinWrite - set a pin HIGH or LOW
* ----------------------------------------------------------------------------
* pin : pin number from 0 to 15
* val : 0=>LOW, !0=>HIGH
******************************************************************************/
void pinWrite(uint8_t pin, uint8_t val)
{
	if (pin > MAXPINS) return;

	/* set or clear the apprporiate port bit */
	if (pinMap[pin][0] == 0) {
		// pin is on Port B
		if (val == 0) {
			/* clear the pin */
			VIA_PORTB = VIA_PORTB & ~pinMap[pin][1];
		} else {
			/* set the pin */
			VIA_PORTB = VIA_PORTB | pinMap[pin][1];
		}
	} else {
		// pin is on Port A
		if (val == 0) {
			/* clear the pin */
			VIA_PORTA = VIA_PORTA & ~pinMap[pin][1];
		} else {
			/* set the pin */
			VIA_PORTA = VIA_PORTA | pinMap[pin][1];
		}
	}
}

/******************************************************************************
* pinDir - set the direction for a port pin
* ----------------------------------------------------------------------------
* pin : pin number from 0 to 15
* dir : 0=>INPUT, 1=>OUTPUT
******************************************************************************/
void pinDir(uint8_t pin, uint8_t dir)
{
	if (pin > MAXPINS) return;

	if (dir == INPUT) {
		/* INPUT = > clear the apprporiate DDR bit */
		if (pinMap[pin][0] == 0) {
			// pin is on Port B so use DDRB
			VIA_DDRB = VIA_DDRB & ~pinMap[pin][1];
		} else {
			// pin is on Port A so use DDRA
			VIA_DDRA = VIA_DDRA & ~pinMap[pin][1];
		}
	}
	else if (dir == OUTPUT) {
		/* OUTPUT = > set the apprporiate DDR bit */
		if (pinMap[pin][0] == 0) {
			// pin is on Port B so use DDRB
			VIA_DDRB = VIA_DDRB | pinMap[pin][1];
		} else {
			// pin is on Port A so use DDRA
			VIA_DDRA = VIA_DDRA | pinMap[pin][1];
		}
	};
}

/******************************************************************************
  #####   #######  ######   #####     #     #       
 #     #  #        #     #    #      # #    #       
 #        #        #     #    #     #   #   #       
  #####   #####    ######     #    #     #  #       
       #  #        #   #      #    #######  #       
 #     #  #        #    #     #    #     #  #       
  #####   #######  #     #  #####  #     #  ####### 
*******************************************************************************
* SCC2691 UART
******************************************************************************/


/******************************************************************************
  #####   ######   ##### 
 #     #  #     #    #  
 #        #     #    #  
  #####   ######     #  
       #  #          #  
 #     #  #          #  
  #####   #        ##### 
*******************************************************************************
* SPI - Software emulation
* SPI signals are configured to match those of the Arduino UNO such that:
*  MOSI = Arduino UNO PB3 = RetroDuino 8085 VIA PB3
*  MISO = Arduino UNO PB4 = RetroDuino 8085 VIA PB4
*  SCK  = Arduino UNO PB5 = RetroDuino 8085 VIA PB5
******************************************************************************/


/******************************************************************************
* spiSetup - sets up the port pins associated with software SPI
*            PB5 (out) = SCK, PB4 (in) = MISO & PB3 (out) = MOSI
******************************************************************************/
void spiSetup( void )
{
	/* Set PB4 as an input and PB3 & PB5 as outputs */
	VIA_DDRB = ( VIA_DDRB & 0xEF ) | 0x28;
	
	/* Set SCK low */
	VIA_PORTB = VIA_PORTB & 0xDF;
}

/******************************************************************************
* spiRead - reads 1 byte from the SPI slave device
* will call spiRead in low_level.asm
* NOTE: Slightly faster than calling spiTransfer
******************************************************************************/
extern uint8_t spiRead( void );

/******************************************************************************
* spiWrite - writes 1 byte to the SPI slave device
* will call spiWrite in low_level.asm
* NOTE: Slightly faster than calling spiTransfer
******************************************************************************/
extern void spiWrite( uint8_t data );

/******************************************************************************
* spiTransfer - exchange 1 byte with an SPI slave device
* will call spiTransfer in low_level.asm
******************************************************************************/
extern uint8_t spiTransfer(uint8_t data);

/******************************************************************************
 #####   #####    #####  
   #    #     #  #     # 
   #          #  #       
   #     #####   #       
   #    #        #       
   #    #        #     # 
 #####  #######   #####  
*******************************************************************************
* I2C - Software emulation
* I2C signals are configured to match those of the Arduino UNO such that:
*  SCL = Arduino UNO PC5 = RetroDuino 8085 VIA PA0
*  SDA = Arduino UNO PC4 = RetroDuino 8085 VIA PA1
******************************************************************************/

/******************************************************************************
* i2cSetup - sets up the port pins associated with software I2C
*            PA0 (out) = SCL & PA1 (out) = SDA
******************************************************************************/
void i2cSetup( void )
{
	/* Set PA0 & PA1 as outputs */
	VIA_DDRA = VIA_DDRA | 0x03;
	
	/* Set SCL & SDA HIGH */
	VIA_PORTA = VIA_PORTA | 0x03;
}

/******************************************************************************
* i2cStart - generates the START condition and outputs the address byte
* NOTE: Address should include the R/W bit in bit position 0.
******************************************************************************/
extern uint8_t i2cStart( uint8_t devAddr );

/******************************************************************************
* i2cStop - generates the STOP condition
******************************************************************************/
extern void    i2cStop( void );

/******************************************************************************
* i2cReadByte - reads a byte from the I2C bus
* set stopFlag = 1 for last read to generate a NACK
* returns byte read in
******************************************************************************/
extern uint8_t i2cReadByte( uint8_t stopFlag );

/******************************************************************************
* i2cWriteByte - writes a byte out on the I2C bus
* RETURN: 0 = ACK - anything else = NACK
******************************************************************************/
extern uint8_t i2cWriteByte( uint8_t txData );



/******************************************************************************
 #######  ###  #     #  #######  ######    #####  
    #      #   ##   ##  #        #     #  #     # 
    #      #   # # # #  #        #     #  #       
    #      #   #  #  #  #####    ######    #####  
    #      #   #     #  #        #   #          # 
    #      #   #     #  #        #    #   #     # 
    #     ###  #     #  #######  #     #   #####  
******************************************************************************/
extern uint16_t millis( void );

#ifndef HARDWARE_H
#define HARDWARE_H

#define LOW				0
#define HIGH			1

#define INPUT			0
#define OUTPUT			1

#define LED_BUILTIN1	0
#define LED_BUILTIN2	1

/******************************************************************************
ADC0844 Analogue to Digital Converter
******************************************************************************/
uint8_t adcRead( void );
void    adcStartConversion( uint8_t ch );

/******************************************************************************
W65C22S Versatile Interface Adapter
******************************************************************************/
uint8_t pinRead(uint8_t pin);
void    pinWrite(uint8_t pin, uint8_t val);
void    pinDir(uint8_t pin, uint8_t dir);

/******************************************************************************
SCC2691 Single Channel UART
******************************************************************************/



/******************************************************************************
SPI - Software Emulation
******************************************************************************/
void    spiSetup( void );
uint8_t spiTransfer(uint8_t data);
uint8_t spiRead( void );
void    spiWrite( uint8_t data );

/******************************************************************************
I2C - Software Emulation
******************************************************************************/
void    i2cSetup( void );
uint8_t i2cStart( uint8_t devAddr );
void    i2cStop( void );
uint8_t i2cReadByte( uint8_t stopFlag );
uint8_t i2cWriteByte( uint8_t data );

/******************************************************************************
TIMERS - millisecond counter
******************************************************************************/
uint16_t millis( void );

#endif
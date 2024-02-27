; This file contains the low level assembler routines to carry out various
; hardware functions etc.
;
; ============================================================================
; SPI Interface - Mode 0 only
; ----------------------------------------------------------------------------
; spiTransfer - exchanges bytes with the remote device
; spiRead     - reads a byte from the remote device
; spiWrite    - writes a byte to the remote device
;
	SECTION		bss_user

	PUBLIC  _sysTick
	
_sysTick:	DEFS	2

	SECTION		code_user
	
; SPI software functions

	PUBLIC	spiTransfer
	PUBLIC	_spiTransfer
	
	PUBLIC	spiRead
	PUBLIC	_spiRead

	PUBLIC	spiWrite
	PUBLIC	_spiWrite

; I2C software functions

	PUBLIC	i2cStart
	PUBLIC	_i2cStart
	
	PUBLIC	i2cStop
	PUBLIC	_i2cStop
	
	PUBLIC	i2cWriteByte
	PUBLIC	_i2cWriteByte
	
	PUBLIC	i2cReadByte
	PUBLIC	_i2cReadByte

; Timer functions

	PUBLIC	millis
	PUBLIC	_millis
	
; Define the locations of the registers in the 65C22 VIA in I/O space
VIABASE EQU 040H
PORTA   EQU VIABASE+1
PORTB   EQU VIABASE+0
DDRA    EQU VIABASE+3
DDRB    EQU VIABASE+2



;******************************************************************************
;  #####   ######   ##### 
; #     #  #     #    #  
; #        #     #    #  
;  #####   ######     #  
;       #  #          #  
; #     #  #          #  
;  #####   #        #####  
;******************************************************************************
; SPI - Software emulation
; SPI signals are configured to match those of the Arduino UNO such that:
;  MOSI = Arduino UNO PB3 = RetroDuino 8085 VIA PB3
;  MISO = Arduino UNO PB4 = RetroDuino 8085 VIA PB4
;  SCK  = Arduino UNO PB5 = RetroDuino 8085 VIA PB5
;******************************************************************************
; some SPI helper values
SCK_HI    EQU $20       ; OR  value to set SCK  high
SCK_LO    EQU $DF       ; AND value to set SCK  low
MOSI_HI   EQU $08       ; OR  value to set MOSI high
MOSI_LO   EQU $F7       ; AND value to set MOSI low


;******************************************************************************
; spiTransfer - exchange 1 byte with the selected SPI device
; From first rising edge of CLK to last falling edge of CLK is approx 196uS
;******************************************************************************
; uint8_t spiTransfer(uint8_t data)
;******************************************************************************
; REGS:
; A - general use
; B - bit count
; C - holds copies of VIA PORTA
; H - holds byte received
; L - holds byte to send
;******************************************************************************
spiTransfer:
_spiTransfer:
	pop		b			; return address
	pop		h			; byte to send is in L
	push	h			; now put HL & BC back on the stack
	push	b
	
    mvi     b,$08       ; number of bits to shift
    in      PORTB       ; read the current state of Port B
    mov     c,a         ; and save Port B in C	

spxf_nextbit:
    mov     a,l         ; get byte to send
    rlc                 ; bit to send in CARRY flag
    mov     l,a         ; store byte back (carry unaffected)

    ; carry flag holds the bit to go out on MOSI
    mov     a,c         ; get saved port B
    jc      spxf_setmosi
    
    ; carry is 0 so clear MOSI
    ani     MOSI_LO
    jmp     spxf_donemosi
    
spxf_setmosi:    
    ori     MOSI_HI
spxf_donemosi:
    out     PORTB       ; and update the port
    
    ; now set the CLK line HIGH
    ori     SCK_HI      ; set CLK high
    out     PORTB       ; and update the port
    mov     c,a         ; and save updated port B
    
    ; read the state of Port B to read MISO
    in      PORTB       ; read state of Port B    
    rlc                 ; shift state of MISO bit into carry flag
    rlc
    rlc
    rlc
    mov     a,h         ; get received byte
    ral                 ; carry flag -> LSB & MSB -> carry flag
    mov     h,a         ; store byte back
    
    mov     a,c         ; get saved port B
    ani     SCK_LO      ; set CLK low
    out     PORTB       ; write to Port B    
    mov     c,a         ; and save updated port B 
    
    dcr     b           ; decrement number of bits to send
    jnz     spxf_nextbit

    ; transmission complete
	mov		l,h			; transfer recevied byte into LSB
	mvi		h,$00

	ret
	
;******************************************************************************
; spiRead - read 1 byte from the selected SPI device
; From first rsing edge of CLK to last falling edge of CLK is approx 135uS
;******************************************************************************
; uint8_t spiRead( void )
;******************************************************************************
; REGS:
; A - general use
; B - bit count
; C - holds copies of VIA PORTA
; L - holds byte received
;******************************************************************************
spiRead:
_spiRead:
    mvi     b,$08       ; number of bits to shift
    
    in      PORTB       ; read the current state of Port B
    ani     MOSI_LO     ; set MOSI low
    out     PORTB       ; write out to Port B
    mov     c,a         ; and save Port B in C

sprd_nextbit:
    ; set the CLK line HIGH
    ori     SCK_HI      ; set CLK high
    out     PORTB       ; and update the port
    mov     c,a         ; and save updated port B
    
    ; read the state of Port B to read MISO
    in      PORTB       ; read state of Port B    
    rlc                 ; shift state of MISO bit into carry flag
    rlc
    rlc
    rlc
    mov     a,l         ; get received byte
    ral                 ; carry flag -> LSB & MSB -> carry flag
    mov     l,a         ; store byte back
    
    mov     a,c         ; get saved port B
    ani     SCK_LO      ; set CLK low
    out     PORTB       ; write to Port B    
    mov     c,a         ; and save updated port B 
    
    dcr     b           ; decrement number of bits to send
    jnz     sprd_nextbit
    
    ; transmission complete
	; L register holds the received byte
	ret
	
;******************************************************************************
; spiWrite - write 1 byte to the selected SPI device
; From first rsing edge of CLK to last falling edge of CLK is approx 134uS
;******************************************************************************
; void    spiWrite( uint8_t data )
;******************************************************************************
; REGS:
; A - general use
; B - bit count
; C - holds copies of VIA PORTA
; L - holds byte to send
;******************************************************************************
spiWrite:
_spiWrite:
	pop		b			; return address
	pop		h			; byte to send is in L
	push	h			; now put HL & BC back on the stack
	push	b
	
    mvi     b,$08       ; number of bits to shift
    
    in      PORTB       ; read the current state of Port B
    mov     c,a         ; and save Port B in C

spwr_nextbit:
    mov     a,l         ; get byte to send
    rlc                 ; bit to send in CARRY flag
    mov     l,a         ; store byte back (carry unaffected)

    ; carry flag holds the bit to go out on MOSI
    mov     a,c         ; get saved port B
    jc      spwr_setmosi
    
    ; carry is 0 so clear MOSI
    ani     MOSI_LO
    jmp     spwr_donemosi
    
spwr_setmosi:    
    ori     MOSI_HI
spwr_donemosi:
    out     PORTB       ; and update the port

    ; now set the CLK line HIGH
    ori     SCK_HI      ; set CLK high
    out     PORTB       ; and update the port
	nop
    ani     SCK_LO      ; set CLK low
    out     PORTB       ; write to Port B    
    mov     c,a         ; and save updated port B 
    
    dcr     b           ; decrement number of bits to send
    jnz     spwr_nextbit
	
    ; transmission complete
	ret

;******************************************************************************
; #####   #####    #####  
;   #    #     #  #     # 
;   #          #  #       
;   #     #####   #       
;   #    #        #       
;   #    #        #     # 
; #####  #######   #####  
;******************************************************************************
; I2C - Software emulation
; I2C signals are configured to match those of the Arduino UNO such that:
;  SCL = Arduino UNO PC5 = RetroDuino 8085 VIA PA0
;  SDA = Arduino UNO PC4 = RetroDuino 8085 VIA PA1
;******************************************************************************
; some I2C helper values
SCL_H   EQU $01         ; OR  value to set SCL high
SCL_L   EQU $FE         ; AND value to set SCL low
SDA_H   EQU $02         ; OR  value to set SDA high
SDA_L   EQU $FD         ; AND value to set SDA low
SDA_IN	EQU $FD			; AND value to set SDA as an input
SDA_OUT EQU $02         ; OR  value to set SDA as an output
SCL_OUT EQU $01         ; OR  value to set SCL as an output

;******************************************************************************
; generate an I2C START condition
;******************************************************************************
; uint8_t i2cStart( uint8_t devAddr )
;******************************************************************************
; REGS:
; A - general use
;******************************************************************************
i2cStart:
_i2cStart:
	in      PORTA       ; read the current state of Port A
    ani     SDA_L       ; set SDA low
    out     PORTA       ; write out to Port A
	nop
	jmp		i2cWriteByte
		
;******************************************************************************
; generate an I2C STOP condition
;******************************************************************************
; void    i2cStop( void )
;******************************************************************************
; REGS:
; A - general use
;******************************************************************************
i2cStop:
_i2cStop:
	in      PORTA       ; read the current state of Port A
    ani     SDA_L       ; set SDA low
    ani     SCL_L       ; set SCL low
    out     PORTA       ; write out to Port A
    ori     SCL_H       ; set SCL high
    out     PORTA       ; and update the port
    ori     SDA_H
    out     PORTA       ; and update the port
	ret

;******************************************************************************
; write a byte onto the I2C bus and wait for ACK or NACK
; NOTE: byte to write is on the stack
;******************************************************************************
; uint8_t i2cWriteByte( uint8_t data )
;******************************************************************************
; REGS:
; A - general use
; B - bit count
; C - holds copies of VIA PORTA
; L - holds byte to send
;******************************************************************************
i2cWriteByte:
_i2cWriteByte:
	pop		b			; return address
	pop		h			; byte to send is in L
	push	h			; now put HL & BC back on the stack
	push	b

    mvi     b,$08       ; number of bits to shift
	
i2WRnextbit:
	; Acc already holds PORT A
    ani     SCL_L       ; set SCL low
    out     PORTA       ; write out to Port A
    mov     c,a         ; and save Port A in C

	; SCL is LOW so now update SDA 
    mov     a,l         ; get byte to send
    rlc                 ; bit to send in CARRY flag
    mov     l,a         ; store byte back (carry unaffected)

    ; carry flag holds the bit to go out on SDA
    mov     a,c         ; get saved port A
    jc      i2WRsetsda
    
    ; carry is 0 so clear SDA
    ani     SDA_L
    jmp     i2WRdonesda
    
i2WRsetsda:    
    ori     SDA_H
i2WRdonesda:
    out     PORTA       ; and update the port
    
    ; set the SCL line HIGH
    ori     SCL_H       ; set SCL high
    out     PORTA       ; and update the port

    dcr     b           ; decrement number of bits to send
    jnz     i2WRnextbit
    
    ; transmission complete - set SCL low
	; Acc already holds PORT A
    ani     SCL_L       ; set SCL low
    out     PORTA       ; write out to Port A
    mov     c,a         ; and save Port A in C

    ; SETUP FOR ACK / NACK
	; set SDA as an input ready to receive the ACK / NACK
	in		DDRA
	ani		SDA_IN
	out		DDRA

	; set SCL high
    mov     a,c         ; get saved port A
    ori     SCL_H       ; set SCL high
    out     PORTA       ; and update the port
    mov     c,a         ; and save Port A in C
	nop
    nop
    
	; check SDA pin level 
	in		PORTA
	ani		SDA_H
	; A is $02 if NACK or $00 if ACK
	mov		l,a			; save ACK / NACK state

	; set SCL low
    mov     a,c         ; get saved port A
    ani     SCL_L       ; set SCL low
    out     PORTA       ; write out to Port A
	
	; set SDA HIGH and configure as OUTPUT
    ori     SDA_H
    out     PORTA       ; write out to Port A (won't change till DDR changed)

	in		DDRA
	ori		SDA_OUT
	out		DDRA

	; L holds $00 if ACK or $02 if NACK
	ret
	
;******************************************************************************
; read a byte from the I2C bus and send ACK
;******************************************************************************
; uint8_t i2cReadByte( uint8_t stopFlag )
;******************************************************************************
; REGS:
; A - general use
; B - bit count
; C - holds copies of VIA PORTA
; E - holds ACK / NACK flag
; L - holds received byte
;******************************************************************************
i2cReadByte:
_i2cReadByte:
	pop		b			; return address
	pop		d			; ACK / NACK flag (i.e. stopFlag) is now in E
	push	d			; now put BC & DE back on the stack
	push	b

    mvi     b,$08       ; number of bits to shift

	; set SDA as an input ready to receive the byte
	in		DDRA
	ani		SDA_IN
	out		DDRA

	in		PORTA		; read state of Port A

i2RDnextbit:
	; Acc holds state of Port A
    ori     SCL_H       ; set SCL high
    out     PORTA       ; and update the port
    mov     c,a         ; and save Port A in C
	nop
    nop
    
	; check SDA pin level 
	in		PORTA
	ani		SDA_H		; A is $02 if SDA = 1 or $00 SDA = 0
	rrc
	rrc
						; carry holds the value of the SDA line
	mov		a,l			; put carry into LSB of L
	ral
	mov		l,a
	
	; set SCL low
    mov     a,c         ; get saved port A
    ani     SCL_L       ; set SCL low
    out     PORTA       ; write out to Port A

    dcr     b           ; decrement number of bits to send
    jnz     i2RDnextbit
	
    mov     c,a         ; and save Port A in C

	; complete byte received and saved in L
	; if stopFlag (i.e. E reg) is NOT zero the send a NACK
	mov		a,e
	cpi		$00
	jnz		i2RDnack

	; send ACK - i.e. SDA = LOW
    mov     a,c         ; get saved port A
    ani     SDA_L
	jmp		i2RDdone
	
i2RDnack:	
	; send NACK - i.e. SDA = HIGH
    mov     a,c         ; get saved port A
    ori     SDA_H
	
i2RDdone:
    out     PORTA       ; write out to Port A (won't change till DDR changed)
    mov     c,a         ; and save Port A in C

	in		DDRA
	ori		SDA_OUT
	out		DDRA

	; set SCL high then low to ACK or NACK the recevied byte
    mov     a,c         ; get saved port A
    ori     SCL_H       ; set SCL high
    out     PORTA       ; and update the port
	nop
    nop
    ani     SCL_L       ; set SCL low
    out     PORTA       ; write out to Port A
    
	; at this point, L holds the received byte
	mvi		h,$0

	ret
	
;******************************************************************************
; #######  #####  #     #  #######  ######    #####  
;    #       #    ##   ##  #        #     #  #     # 
;    #       #    # # # #  #        #     #  #       
;    #       #    #  #  #  #####    ######    #####  
;    #       #    #     #  #        #   #          # 
;    #       #    #     #  #        #    #   #     # 
;    #     #####  #     #  #######  #     #   #####  
;******************************************************************************

;******************************************************************************
; return the current system tick value
;******************************************************************************
; uint16_t millis( void );
;******************************************************************************
millis:
_millis:
	di					; disable interupts
	lhld	_sysTick	; get the system tick value	
	ei					; enable interrupts
	ret
	
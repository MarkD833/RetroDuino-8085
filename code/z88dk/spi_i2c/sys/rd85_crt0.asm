; CRT0 module for the RetroDuino-8085 board
;
; Based on a configurable CRT for bare-metal: z80_crt0.asm
; as well as micro8085_crt0.asm by Anders Hjelm
;
; WARNING: Beyond hear be dragons, lots of dragons ...

    MODULE rd85_crt0 

;------------------------------------------------------------------------------
; Include zcc_opt.def to find out information about us
;------------------------------------------------------------------------------

    defc    crt0 = 1
    INCLUDE "zcc_opt.def"
	
;------------------------------------------------------------------------------
; Some general scope declarations
;------------------------------------------------------------------------------

    EXTERN    _main           ;main() is always external to crt0 code

	PUBLIC fputc_cons_native
	PUBLIC _fputc_cons_native

	PUBLIC fgetc_cons
	PUBLIC _fgetc_cons

; Definitions of the SCC2691 UART
DEFC	UART_BASE      = 00h
DEFC	UART_MODE_REG  = UART_BASE
DEFC	UART_CLK_REG   = UART_BASE + 1
DEFC	UART_STAT_REG  = UART_BASE + 1
DEFC	UART_CMD_REG   = UART_BASE + 2
DEFC	UART_TX_REG	   = UART_BASE + 3
DEFC	UART_RX_REG    = UART_BASE + 3
DEFC	UART_ISTAT_REG = UART_BASE + 5
DEFC	UART_IMASK_REG = UART_BASE + 5
DEFC	UART_CT_HI_REG = UART_BASE + 6
DEFC	UART_CT_LO_REG = UART_BASE + 7

	defc    CRT_ORG_CODE = 0x0000
	defc    CRT_ORG_DATA = 0x8000
	defc    CRT_ORG_BSS  = 0x8000
	
	defc	RAM_TOP		 = 0xFFF0
	
	defc    REGISTER_SP = RAM_TOP
	defc    CLIB_EXIT_STACK_SIZE = 0

	defc    __CPU_CLOCK = 5529600	; half of 11.0592MHz

    INCLUDE "crt/classic/crt_rules.inc"
	
    org    	CRT_ORG_CODE
rst0:
	lxi		sp,__register_sp
	jmp		start 

	defs    $08-ASMPC
rst1:
	ret                     ; RST1 not used

	defs    $10-ASMPC
rst2:
	ret                     ; RST2 not used

	defs    $18-ASMPC
rst3:
	ret                     ; RST3 not used

	defs    $20-ASMPC
rst4:
	ret                     ; RST4 not used

	defs    $24-ASMPC
trap:
	ret                     ; TRAP not used

	defs    $28-ASMPC
rst5:
	ret                     ; RST5 not used

	defs    $2C-ASMPC
rst55:
	ret                     ; RST5.5 not used

	defs    $30-ASMPC
rst6:
	ret                     ; RST6 not used

	defs    $34-ASMPC
rst65:
	ret                     ; RST6.5 not used
		
	defs    $38-ASMPC
rst7:
	ret                     ;RST7 not used

	defs    $3C-ASMPC
rst75:	
	jmp		uart_isr        ; RST7.5 wired to SCC2691 INT pin via GAL
	
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
start:
    INCLUDE "crt/classic/crt_init_atexit.asm"
	call	tgt_init
	call    crt0_init_bss
	call    _main           ; void main(void) so no args or retval

	lxi		h,exitmsg
	call	outstr
infloop:
	jmp     infloop         ; stay here in infinte loop

;------------------------------------------------------------------------------
; target specific initialisation
;------------------------------------------------------------------------------
tgt_init:

	; setup the SCC2691 UART for 19200,8,N,1
	mvi		a,10h			; load the RESET MR POINTER command 
	out		UART_CMD_REG	; write to COMMAND REGISTER
	mvi		a,13h			; 8 DATA BITS + NO PARITY 
	out		UART_MODE_REG	; write to MODE REGISTER #1
	mvi		a,07h			; 1 STOP BIT 
	out		UART_MODE_REG	; write to MODE REGISTER #2
	MVI 	A,0f8h		 	; BRG Set 2, Timer = CLK/16 & Power Down OFF
	OUT 	04h				; write to AUX CTRL REGISTER
	MVI		A,11001100b		; 19200 BAUD for RX & TX 
	out		UART_CLK_REG	; write to CLOCK SELECT REGISTER
	mvi		a,10h			; enable counter/timer interrupt
	out		UART_IMASK_REG	; write to INTERRUPT MASK REGISTER
	mvi		a,05h			; enable TX & RX
	out		UART_CMD_REG	; write to COMMAND REGISTER

	; configure the SCC2691 UART timer for interrupts every
	; 20 milliseconds and start it running
	mvi		a,09h
	out		UART_CT_HI_REG
	mvi		a,0h
	out		UART_CT_LO_REG
	mvi		a,080h
	out		UART_CMD_REG	; write to COMMAND REGISTER
	
	; enable RST7.5 interrupt
	mvi		a, 1Bh
	sim
	
	ret

;------------------------------------------------------------------------------
; output a null terminted string - HL points to 1st character
; don't bother preserving any registers as we're done.
outstr:
	mov		a,m				; get character
	inx		h				; increment ptr to next char
	ana		a				; is it NULL?
	rz						; if yes, then end of mesaage
	mov		b,a				; save char
outstr1:
	in		UART_STAT_REG	; get UART status
	ani 	04h				; test for TxRDY = 1
	jz		outstr1			; not ready - try again
	mov		a,b				; restore char
	out		UART_TX_REG		; write char
	jmp		outstr			; go back for next xhar

;------------------------------------------------------------------------------
; send a character/byte to the UART transmit register
; will wait for TX buffer to empty
fputc_cons_native:
_fputc_cons_native:
    pop     bc  ; return address
    pop     hl  ; character to print in l
    push    hl
    push    bc
	
	mov		a,l			; get the byte to transmit
	cmp		0AH			; is it a linefeed?
    jnz		txl			; not an LF so just print it
    mvi     l,0DH       ; is LF so output a CR first
    call    txl
    mvi     l,0AH       ; then output the LF	
.txl
	in		UART_STAT_REG
	ani		04h		; Test for TxRDY = 1
	jz		txl		; TX not empty - check again
    mov     a,l
    out     UART_TX_REG
    ret

;------------------------------------------------------------------------------
; get a character/byte from the UART receive register
; returns data in L
; will wait until a character/byte is available
fgetc_cons:
_fgetc_cons:
.rxl
	in		UART_STAT_REG
	ani		01h		; Test for RxRDY = 1
	jz		rxl		; Rx buffer empty - check again
	in		UART_RX_REG
    mov     l,a     ;Return the result in hl
    mvi     h,0
    ret

;------------------------------------------------------------------------------
; UART interrupt handler
; currently just the system tick generated from the SCC2691 timer

	EXTERN	_sysTick
	
uart_isr:
	; increment the system tick counter
	push	h
	lhld	_sysTick
	inx		h
	shld	_sysTick
	pop		h
	
	; clear the interrupt flag in the SCC2691 UART
	push	psw
	mvi		a,$90
	out		UART_CMD_REG
	
	; clear the RST7.5 flip flop
	mvi		a,10h
	sim
	
	pop		psw
	ei
	ret
	
exitmsg:
	defb	10,13,"** Exit from main().",10,13,0
	
    INCLUDE "crt/classic/crt_runtime_selection.asm" 
    INCLUDE	"crt/classic/crt_section.asm"
; CRT0 module for the RetroDuino-8085 board
;
; Based on a configurable CRT for bare-metal: z80_crt0.asm
; as well as micro8085_crt0.asm by Anders Hjelm
;
; WARNING: Beyond hear be dragons

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

	defc    CRT_ORG_CODE = 0x0000
	defc    CRT_ORG_DATA = 0x8000
	defc    CRT_ORG_BSS  = 0x8000
	
	defc	RAM_TOP		 = 0xFFF0
	
;------------------------------------------------------------------------------
; UART Rx buffer - align to 256 byte boundary
; and the RD & WR pointers for the Rx buffer
;------------------------------------------------------------------------------

;	defc    _urxbuf   = 0xFF00
;	defc    _putidx   = (_urxbuf-1)		; UART buffer head index
;	defc    _getidx   = (_urxbuf-2)		; UART buffer tail index
;	defc    _mstick   = (_urxbuf-4)		; millisecond tick counter
;	defc    _scrtchpd = (_urxbuf-16)
	
;------------------------------------------------------------------------------
; below UART Rx buffer and some additional data we place the stack
;------------------------------------------------------------------------------

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
	ret                     ;RST7.5 not used
	
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

; setup the SCC2691 UART for 9600,8,N,1
	mvi		a,10h			; load the RESET MR POINTER command 
	out		UART_CMD_REG	; write to COMMAND REGISTER
	mvi		a,13h			; 8 DATA BITS + NO PARITY 
	out		UART_MODE_REG	; write to MODE REGISTER #1
	mvi		a,07h			; 1 STOP BIT 
	out		UART_MODE_REG	; write to MODE REGISTER #2
	mvi		a,0BBh			; 9600 BAUD for RX & TX 
	out		UART_CLK_REG	; write to CLOCK SELECT REGISTER
	mvi		a,0				; no interrupts
	out		UART_IMASK_REG	; write to INTERRUPT MASK REGISTER
	mvi		a,05h			; enable TX & RX
	out		UART_CMD_REG	; write to COMMAND REGISTER

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

exitmsg:
	defb	10,13,"** Exit from main().",10,13,0
	
    INCLUDE "crt/classic/crt_runtime_selection.asm" 
    INCLUDE	"crt/classic/crt_section.asm"
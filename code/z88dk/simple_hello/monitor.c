#include <stdio.h>

int fputc_cons_native(char c) __naked
{
__asm
    pop     bc  ;return address
    pop     hl  ;character to print in l
    push    hl
    push    bc
	
	ld		a,l		; get the character
	cp      0Ah		; is it LF (i.e. \n)?
	jp		nz,txl	; no so just print it
	ld		l,0Dh	; insert a CR
	call	txl		; print it
	ld		l,0Ah	; and then print the LF
.txl
	in		a,(01h)
	ani		04h		; Test for TxRDY = 1
	jz		txl		; TX not empty - check again
    ld      a,l
    out     (03h),a
    ret
__endasm;
} 

int fgetc_cons() __naked
{
__asm
.rxl
	in		a,(01h)
	ani		01h		; Test for RxRDY = 1
	jz		rxl		; Rx buffer empty - check again
	in		a,(03h)
    ld      l,a     ;Return the result in hl
    ld      h,0
    ret
__endasm;
}

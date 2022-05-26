.device ATmega328P
.include "m328pdef.inc"

.cseg
.org 0
	rjmp main

						; Interrupt table goes here
.org 26					; Make sure the code is after the interrupt table

main:
						; First, configure the stack pointer
	ldi r16, 0x5f
	ldi r17, 0x04
	out SPL, r16
	out SPH, r17
						; Next, configure PORTC as out
	ldi r17, 0x0f		; Everything is write
	out DDRC, r17
						; Now write a 1 to bit PC0
	ldi r16, 0x00
	out PORTC, r16
						; Finally, spin
loop:
	nop
	rjmp loop
.device ATmega328P
.include "m328pdef.inc"

.cseg
.org 0
	rjmp main

.org    0x0016
	rjmp     timer1
						; Interrupt table goes here
.org INT_VECTORS_SIZE 	; Make sure the code is after the interrupt table

main:
						; First, configure the stack pointer
	ldi r16, 0x5f
	ldi r17, 0x04
	out SPL, r16
	out SPH, r17
						; Next, configure PORTC as out
	ldi r17, 0x0f		; Everything is set to write
	out DDRC, r17

						; Configure the timer
	ldi r16, 0b00000010 
    sts TIMSK1, r16
    ldi r16, 0b00000000
    sts TCCR1A, r16
	ldi r16, 0b00000100
    sts TCCR1B, r16
    ldi r16, 0b00001111
    ldi r17, 0b00001001 
    sts OCR1AH, r16
    sts OCR1AL, r17
						; Start interrupts
	sei
						; Now write a 1 to bit PC0
	ldi r16, 0x01
	out PORTC, r16
						; Finally, spin
loop:
	nop
	rjmp loop

timer1:
    ldi r17, 0
    sts TCNT1H, r17
    sts TCNT1L, r17
	ldi	r17, 0x01
	eor r16, r17
	out PORTC, r16
	reti
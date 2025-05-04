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
						; We will use PORTD for input
	ldi r17, 0b00001111
	out DDRD, r17

	ldi r17, 0xff       ; Enable pullup
	out PORTD, r17

						; Configure the timer
						; First, configure the clock. We want 100Hz, and the clock rate is 1MHz (the crystal is 8MHz but it is already pre-scaled by 8) 
						; This gives us (1000000/((1249+1)*8))
	ldi r16, 0b00000010 ; Turn on the Output-compare-match flag
    sts TIMSK1, r16
    ldi r16, 0b00000000
    sts TCCR1A, r16
	ldi r16, 0b00001010 ; Set the prescale to 8
    sts TCCR1B, r16
						; Then set the counter to 1249
    ldi r16, 0b00000100
    ldi r17, 0b11100001
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
						; First, reset the timer
    ldi r17, 0
    sts TCNT1H, r17
    sts TCNT1L, r17
						; Check if the button is pressed
	in r16, PIND
	andi r16, 1
						; Button pressed means we have read 0. Switch to 1
	ldi	r17, 0x01
	eor r16, r17
						; Write to C port
	out PORTC, r16

	reti
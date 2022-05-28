.device ATmega328P
.include "m328pdef.inc"


; PORTC0 (out) is the orange LED
; PORTC1 (out) is the red LED
; PORTC2 (out) is the motor control
; PORTD0 (in) is the switch

; r16 holds the status of the button (debounced)
; r18 holds the debounce info
; r20 holds the state 
; r25 is used to save SREG during interrupts. Dont use it in the main loop!

; There are 5 states, and conveniently the state happens to correspond to the values in PORTC!
; State0: Waiting for something to happen (orange off, red off, motor off)
; State1: Button pressed, waiting for latch (orange on, red off motor off)
; State2: Button latched (orange off, red on, motor off)
; State3: Button unpressed, waiting for unlatch (orange on, red on, motor off)
; State4: Motor running (orange off, red off, motor on)


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
						; We will use the low 4 nibble of PORTD for input
	ldi r17, 0b00001111
	out DDRD, r17

	ldi r17, 0xff       ; Enable pullup on all PORTD
	out PORTD, r17

						; Now configure the timer
						; We want 10Hz, and the clock rate is 1MHz (the crystal is 8MHz but it is already pre-scaled by 8) 
						; This gives us (1000000/((12499+1)*8))
	ldi r16, 0b00000010 ; Turn on the Output-compare-match flag
    sts TIMSK1, r16
    ldi r16, 0b00000000
    sts TCCR1A, r16
	ldi r16, 0b00001010 ; Set the prescale to 8
    sts TCCR1B, r16
						; Then set the counter to 12499
    ldi r16, 0b00110000 
    ldi r17, 0b11010011
    sts OCR1AH, r16
    sts OCR1AL, r17

	ldi r18, 0			; Load debounce register
	ldi r16, 0			; Load button status register
	ldi r20, 0			; Load state register
						; Start interrupts
	sei
						; Finally, main loop
loop:
						; FIXME: Replace with a jump table
						; FIXME: When in state 0 we should probably sleep until the switch wakes us
	out PORTC, r20
	cpi r20, 0
	breq state0
	cpi r20, 1
	breq state1
	cpi r20, 2
	breq state2
	cpi r20, 3
	breq state3
	cpi r20, 4
	breq state4
	rjmp loop

nervous:
						; We get here if the button was unpressed too briefly in state3 and we cannot move to state 4. We end up back in state 2
	ldi r20, 2
	out PORTC, r20
	rjmp loop

misfire:
						; We get here if we thought there was a button press but it was not enough to get to state 2
	ldi r20, 0			; Move to state 0
	out PORTC, r16		; Set/clear the orange LED
						; Fall through to state0

state0:
						; In state 0, we are waiting for a button press
	sbrs r16, 0			; Skip the next line if button is pressed
	rjmp loop			; If no button press, we are done
	ldi r20, 1			; If we detect a button press, start the counter and go to state 1
	ldi r21, 50
	out PORTC, r20		; Set the orange LED
						; Fall through to state 1
state1:
						; In state 1, we are waiting to run the timer out. The orange LED is lit
	cpi r16, 1			; First, check if the button is still pressed
	brne misfire		; Oops, go back to state 0
	cpi r21, 0			; Otherwise, check the status of the counter. If it is zero, we can move to state 2
	brne loop			; If not 0, then keep looping
						; Moving to state 2
	ldi r20, 2
	out PORTC,  r20		; Conveniently, the state is now also the value we would want to write to PORTC to turn off the orange and on the red LED
						; Fall through to state 2
state2:
						; In state 2 we are waiting for the button to become unpressed
	cpi r16, 1			; Is the button pressed?
	breq loop			; If yes, then loop
						; If no, then move to state 3
	ldi r21, 50  		; Start the counter
	ldi r20, 3
	out PORTC, r20		; Again, conveniently, both lights should be on in state 3

state3:
						; In state 3 we are waiting for the timer to run out. The orange LED is lit again
	cpi r16, 1			; First, check if the button is still pressed
	breq nervous		; Oops, go back to state 2
	cpi r21, 0			; Otherwise, check the status of the counter. If it is zero, we can move to state 4
	brne loop			; If not 0, then keep looping
						; Moving to state 4
	ldi r20, 4
	out PORTC,  r20		; Conveniently, the state is once again the value we would want to write to PORTC to turn off the orange and off the red LED and turn the motor
	ldi r21, 100		; Reload the counter

state4:
						; in state4 we just wait for 10 seconds then move to state0
	cpi r21, 0			; Check the counter
	brne loop			; If not finished, loop
	ldi r20, 0			; Otherwise, go to state 0
	out PORTC, r20		
	rjmp loop
	


timer1:
	in r25, SREG		; save SREG!
						; First, reset the timer
    ldi r17, 0
    sts TCNT1H, r17
    sts TCNT1L, r17
						; Check if the button is pressed
	in r17, PIND
	andi r17, 1

						; Debounce. 
						; Shift r18 left and insert the current PIND0 on the right
	lsl r18
	or r18, r17
	cpi r18, 0x80		; If 0b10000000 then we have just detected the switch is on
	brne notPressed
	ldi r16, 1			; Set r16 to indicate switch is on
	rjmp notReleased
notPressed:
	cpi r18, 0x7f		; If 0b01111111 then we have just detected the switch is off
	brne notReleased		
	ldi r16, 0			; Set r16 to indicate switch is off
notReleased:
						; End of debounce

	dec r21				; Decrement the timer in case we are in state 1 or 2
	out SREG, r25		; Restore SREG
	reti
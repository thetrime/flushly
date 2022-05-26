# inc was copied from C:\Program Files (x86)\Atmel\Studio\7.0\packs\atmel\ATmega_DFP\1.6.364\avrasm
# because I could not work out the syntax for Microsoft's insane file structure

# The path for avrasm2 can be achieved with
# set PATH=%PATH%;"c:\Program Files (x86)\Atmel\Studio\7.0\toolchain\avr8\avrassembler;c:\opt\avrdude" 

# Why am I not just using Linux? :(

all: one.asm
	avrasm2 -fI -Iinc -o one.hex one.asm

deploy: one.hex
	avrdude -p atmega328p -c usbasp-clone -U flash:w:one.hex:i
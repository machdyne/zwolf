; count forever

main:
	li 0x10		; gpio direction ctrl port
	swap
	li 0xff		; set all gpios to outputs
	sio
	li 0xff		; initial counter value
	push			; push counter

loop:
	pop			; pop counter
	swap			; b = counter
	li 1
	add			; a = 1 + counter
	swap			; b = counter

	li 0x11		; gpio data port
	swap

	sio			; write counter to gpio data port

	push			; push counter

	li loop_hi
	swap
	li loop_lo
	jp

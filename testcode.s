	.text
	.globl  main
fib.9:
	blti	$r01, 2, bge_else.22
	subi	$r02, $r01, 1
	store	$r01, $r14, 0
	load	$r11, $r14, -4
	mov	$r01, $r02
	store	$r11, $r14, 4
	addil	$r14, $r14, 8
	call	fib.9
	subi	$r14, $r14, 8
	load	$r11, $r14, 4
	store	$r11, $r14, -4
	load	$r02, $r14, 0
	subi	$r02, $r02, 2
	store	$r01, $r14, 4
	load	$r11, $r14, -4
	mov	$r01, $r02
	store	$r11, $r14, 12
	addil	$r14, $r14, 16
	call	fib.9
	subi	$r14, $r14, 16
	load	$r11, $r14, 12
	store	$r11, $r14, -4
	load	$r02, $r14, 4
	add	$r01, $r02, $r01, 0
	ret
bge_else.22:
	li	$r01, 1
	ret
main: # main entry point
   # main program start
	li	$r01, 10
	load	$r11, $r14, -4
	store	$r11, $r14, 4
	addil	$r14, $r14, 8
	call	fib.9
	subi	$r14, $r14, 8
	load	$r11, $r14, 4
	store	$r11, $r14, -4
   # main program end
	beq	$r00, $r00, $r15, 0
	.data
fzero:
	.float	0.000000
l.105:
	.float	1.000000
l.104:
	.float	1.500000
l.103:
	.float	128.000000
l.102:
	.float	4.000000
	.text
	.globl  main
dbl.40:
	fadd	$f01, $f01, $f01
	ret
iloop.56:
	beqi	$r01, $r00, bne_else.121
	fsub	$f03, $f03, $f04
	fadd	$f03, $f03, $f05
	fstore	$f05, $r14, 0
	store	$r01, $r14, 8
	fstore	$f03, $r14, 16
	fstore	$f06, $r14, 24
	fstore	$f02, $r14, 32
	addil	$r14, $r14, 48
	call	dbl.40
	subi	$r14, $r14, 48
	fload	$f02, $r14, 32
	fmul	$f01, $f01, $f02
	fload	$f06, $r14, 24
	fadd	$f02, $f01, $f06
	fload	$f01, $r14, 16
	fmul	$f03, $f01, $f01
	fmul	$f04, $f02, $f02
	fload	$f05, $r00, l.102
	fadd	$f07, $f03, $f04
	bflti	$f05, $f07, bfge_else.123
	load	$r01, $r14, 8
	subi	$r01, $r01, 1
	fload	$f05, $r14, 0
	beqi	 $r00, $r00, iloop.56
bfge_else.123:
	li	$r01, 49
	write	$r01
	ret
bne_else.121:
	li	$r01, 48
	write	$r01
	ret
xloop.46:
	li	$r03, 128
	blti	$r01, $r03, bge_else.126
	ret
bge_else.126:
	itof	$f01, $r01
	store	$r01, $r14, 0
	store	$r02, $r14, 4
	addil	$r14, $r14, 16
	call	dbl.40
	subi	$r14, $r14, 16
	fload	$f02, $r00, l.103
	finv	$f03, $f02
	fmul	$f01, $f01, $f03
	fload	$f03, $r00, l.104
	fsub	$f01, $f01, $f03
	load	$r01, $r14, 4
	itof	$f03, $r01
	fstore	$f01, $r14, 8
	fstore	$f02, $r14, 16
	fadd	$f01, $f00, $f03
	addil	$r14, $r14, 32
	call	dbl.40
	subi	$r14, $r14, 32
	fload	$f02, $r14, 16
	finv	$f02, $f02
	fmul	$f01, $f01, $f02
	fload	$f02, $r00, l.105
	fsub	$f06, $f01, $f02
	li	$r01, 1000
	fadd	$f01, $f00,  $f00
	fload	$f05, $r14, 8
	fadd	$f04, $f00, $f01
	fadd	$f03, $f00, $f01
	fadd	$f02, $f00, $f01
	addil	$r14, $r14, 32
	call	iloop.56
	subi	$r14, $r14, 32
	load	$r01, $r14, 0
	addil	$r01, $r01, 1
	load	$r02, $r14, 4
	beqi	 $r00, $r00, xloop.46
yloop.42:
	li	$r02, 128
	blti	$r01, $r02, bge_else.128
	ret
bge_else.128:
	li	$r02, 0
	store	$r01, $r14, 0
	mov	$r09, $r02
	mov	$r02, $r01
	mov	$r01, $r09
	addil	$r14, $r14, 12
	call	xloop.46
	subi	$r14, $r14, 12
	load	$r01, $r14, 0
	addil	$r01, $r01, 1
	beqi	 $r00, $r00, yloop.42
main: # main entry point
   # main program start
	li	$r01, 0
	addil	$r14, $r14, 8
	call	yloop.42
	subi	$r14, $r14, 8
   # main program end
	beq	$r00, $r00, $r15, 0

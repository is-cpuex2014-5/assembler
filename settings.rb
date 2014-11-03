module Settings
	def self.macros
		{
			mov:	[	"add	%1%,	%2%,	$r00,	0"	],
			li:		[	"addi	%1%,	$r00,	L,	%2%"	],
			lis:	[	"addi	%1%,	$r00,	H,	%2%"	],
			addil:	[	"addi	%1%,	%2%,	L,	%3%"	],
			addih:	[	"addi	%1%,	%2%,	H,	%3%"	],
			call:	[	"addi	$r11,	$r15,	L,	16",
						"store	$r11,	$r14,	0",
						"addi	$r14,	$r14,	L,	4",
						"beq	$r00,	$r00,	%1%"	],
			ret:	[	"subi	$r14,	$r14,	4",
						"load	$r15,	$r14,	0"	],
			sll:	[	"shift	%1%,	%2%,	%3%,	0,	l,	logic"	],
			srl:	[	"shift	%1%,	%2%,	%3%,	0,	r,	logic"	],
			sla:	[	"shift	%1%,	%2%,	%3%,	0,	l,	arith"	],
			sra:	[	"shift	%1%,	%2%,	%3%,	0,	r,	arith"	],
			slli:	[	"shifti	%1%,	%2%,	$r00,	%3%,	l,	logic"	],
			srli:	[	"shifti	%1%,	%2%,	$r00,	%3%,	r,	logic"	],
			slai:	[	"shifti	%1%,	%2%,	$r00,	%3%,	l,	arith"	],
			srai:	[	"shifti	%1%,	%2%,	$r00,	%3%,	r,	arith"	],
			# branch macros
		}
	end

	def self.instructions
		{
			add:	[	"0000000",	:reg,	:reg,	:reg,	:imm13	],
			addi:	[	"0000001",	:reg,	:reg,	:hl,	:imm16	],
			sub:	[	"0000010",	:reg,	:reg,	:reg	],
			subi:	[	"0000011",	:reg,	:reg,	"0",	:imm16	],
			not:	[	"0000100",	:reg,	:reg,	:reg,	"0000000000000"	],
			and:	[	"0000110",	:reg,	:reg,	:reg,	"0000000000000"	],
			or:		[	"0001000",	:reg,	:reg,	:reg,	"0000000000000"	],
			xor:	[	"0001010",	:reg,	:reg,	:reg,	"0000000000000"	],
			nand:	[	"0001100",	:reg,	:reg,	:reg,	"0000000000000"	],
			nor:	[	"0001110",	:reg,	:reg,	:reg,	"0000000000000"	],
			shift:	[	"0010000",	:reg,	:reg,	:reg,	:imm05,	:lr,	:la,	"00000"	],
			shifti:	[	"0010001",	:reg,	:reg,	:reg,	:imm05,	:lr,	:la,	"00000"	],

			fadd:	[	"0100000",	:reg,	:reg,	:reg,	"0000000000000"	],
			fsub:	[	"0100010",	:reg,	:reg,	:reg,	"0000000000000"	],
			fmul:	[	"0100100",	:reg,	:reg,	:reg,	"0000000000000"	],
			fdiv:	[	"0100110",	:reg,	:reg,	:reg,	"0000000000000"	],
			fsqrt:	[	"0101000",	:reg,	:reg,	"00000000000000000"	],
			ftoi:	[	"0101010",	:reg,	:reg,	"00000000000000000"	],
			itof:	[	"0101100",	:reg,	:reg,	"00000000000000000"	],
			fneg:	[	"0101110",	:reg,	:reg,	"00000000000000000"	],
			finv:	[	"0110000",	:reg,	:reg,	"00000000000000000"	],

			beq:	[	"1000000",	:reg,	:reg,	:reg,	"0000000000000"	],
			beqi:	[	"1000001",	:reg,	:reg,	:imm17	],
			blt:	[	"1000010",	:reg,	:reg,	:reg,	"0000000000000"	],
			blti:	[	"1000011",	:reg,	:reg,	:imm17	],
			bfeq:	[	"1000100",	:reg,	:reg,	:reg,	"0000000000000"	],
			bfeqi:	[	"1000101",	:reg,	:reg,	:imm17	],
			bflt:	[	"1000110",	:reg,	:reg,	:reg,	"0000000000000"	],
			bflti:	[	"1000111",	:reg,	:reg,	:imm17	],

			load:	[	"1100000",	:reg,	:reg,	:imm17	],
			store:	[	"1100010",	:reg,	:reg,	:imm17	],
			fload:	[	"1100100",	:reg,	:reg,	:imm17	],
			fstore:	[	"1100110",	:reg,	:reg,	:imm17	],
			loadr:	[	"1101000",	:reg,	:reg,	:reg,	"0000000000000"	],
			storer:	[	"1101010",	:reg,	:reg,	:reg,	"0000000000000"	],
			floadr:	[	"1101100",	:reg,	:reg,	:reg	],
			fstorer:[	"1101110",	:reg,	:reg,	:reg	],
	
			read:	[	"1110000",	:reg,	"000000000000000000000"	],
			write:	[	"1110001",	:reg,	"000000000000000000000"	],

			# dot instructions
			dfloat:	[	:immfl	],
			dint:	[	:imm32	],
		}
	end
end
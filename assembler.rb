class Assembler
	def initialize
		@codes = []
		@labels = {}
		@macros = {
			mov:	[	"add	%1%,	%2%,	$r00,	0"	],
			li:		[	"addi	%1%,	$r00,	L,	%2%"	],
			lis:	[	"addi	%1%,	$r00,	H,	%2%"	],
			addil:	[	"addi	%1%,	%2%,	L,	%3%"	],
			addih:	[	"addi	%1%,	%2%,	H,	%3%"	],
			call:	[	"addi	$r11,	$r15,	4",
						"store	$r11,	$r14,	0",
						"addi	$r14,	$r14,	4",
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
		}
		@instructions = {
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
			shift:	[	"0010000",	:reg,	:reg,	:reg,	:imm05,	:lr,	:la	],
			shifti:	[	"0010001",	:reg,	:reg,	:reg,	:imm05,	:lr,	:la	],

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
			beqi:	[	"1000001",	:reg,	:reg,	:lb	],
			blt:	[	"1000010",	:reg,	:reg,	:reg,	"0000000000000"	],
			blti:	[	"1000011",	:reg,	:reg,	:lb	],
			bfeq:	[	"1000100",	:reg,	:reg,	:reg,	"0000000000000"	],
			bfeqi:	[	"1000101",	:reg,	:reg,	:lb	],
			bflt:	[	"1000110",	:reg,	:reg,	:reg,	"0000000000000"	],
			bflti:	[	"1000111",	:reg,	:reg,	:lb	],

			load:	[	"1100000",	:reg,	:reg,	:imm17	],
			store:	[	"1100010",	:reg,	:reg,	:imm17	],
			# fload:	[	"1100100",	:reg,	:reg,	:reg	],
			# fstore:	[	"1100110",	:reg,	:reg,	:reg	],
			loadr:	[	"1101000",	:reg,	:reg,	:reg,	"0000000000000"	],
			storer:	[	"1101010",	:reg,	:reg,	:reg,	"0000000000000"	],
			# floadr:	[	"1101100",	:reg,	:reg,	:reg	],
			# fstorer:	[	"1101110",	:reg,	:reg,	:reg	],
		}
	end

	def run filename
		# マクロの展開
		src = File.read(filename)
		src = "\tbeqi $r00 $r00 main\n" + src
		@codes = src.split "\n"
		pre_process
		label_to_lmap
		ascii = encode_lines
		print bin2ascii(ascii)
	end

	def pre_process
		@codes.map! do |code|
			code = remove_comment_of code
			case instruction_type_of code
			when :blank, :dot
				nil
			when :label, :native
				code
			when :macro
				expand_macro code
			end
		end
		@codes.flatten!
		@codes.delete(nil)
	end

	def instruction_type_of code
		head = code.split[0]
		return :blank unless head
		return :dot if head[0] == "."
		return :macro if @macros.keys.include? head.to_sym
		return :label if head[-1] == ":"
		return :native
	end

	def label_to_lmap
		address = 0
		@codes.map! do |code|
			case instruction_type_of(code)
			when :label
				@labels[code.split[0].chop] = address * 4
				nil
			when :native
				address += 1
				code
			end
		end
		@codes.delete(nil)
	end

	def encode_lines
		# 命令とレジスタとラベルの展開
		ascii = ""
		@codes.each_with_index do |code, i|
			ascii << encode_line(code)
			# printf "%04d : %08x %s\n", i, encode_line(code).to_i(2), code.gsub(/( |\n|\n|\r|\t)+/," ")
		end
		return ascii
	end 

	def bin2ascii str
		a = str.scan(/.{1,8}/)
		a = a.map { |s| ("0b" + s).to_i(0) }
		ret = a.inject("") { |out, i | out += i.chr }  
	end

	def remove_comment_of line
		if line.index("#")
			line = line[0...line.index("#")] << "\r\n"
		else
			line
		end
	end

	def expand_macro line
		opes = (line.gsub ",", "").split
		structure = @macros[opes.shift.to_sym].join("\n")
		raise "unknown macro: #{(line.gsub ",", "").split[0]}" unless structure
		opes.each_with_index do |ope, i|
			structure.sub!("%#{i+1}%", ope)
		end
		structure.split("\n")
	end

	def encode_line line
		opes = (line.gsub ",", "").split
		structure = @instructions[opes.shift.to_sym]
		raise "unknown opecode: #{(line.gsub ",", "").split[0]}" unless structure

		structure.inject("") do |acc, elm|
			case elm
			when Symbol
				acc + bin_of(elm, opes.shift)
			when String
				acc + elm
			else
				raise "instructions def error"
			end
		end
	end

	def bin_of type, expr
		case type
		when :reg
			sprintf "%04b", expr.slice(2,2).to_i
		when :lr
			(expr == "l") ? "0" : "1"
		when :hl
			(expr == "L") ? "0" : "1"
		when :la
			(expr == "logic") ? "00" : "01"
		when :lb
			sprintf "%017b", @labels[expr]
		when :imm05
			ret = sprintf "%05b", expr.to_i
			(expr.to_i > 0) ? ret : ret.sub("..","11")[-5,5]
		when :imm13
			ret = sprintf "%013b", expr.to_i
			(expr.to_i > 0) ? ret : ret.sub("..","11")[-13,13]
		when :imm16
			ret = sprintf "%016b", expr.to_i
			(expr.to_i > 0) ? ret : ret.sub("..","11")[-16,16]
		when :imm17
			ret = sprintf "%017b", expr.to_i
			(expr.to_i > 0) ? ret : ret.sub("..","11")[-17,17]
		else
			raise "unknown ope type: #{type}"
		end
	end

	private
	def self.int?(str)
	  Integer(str)
	  true
	rescue ArgumentError
	  false
	end
end

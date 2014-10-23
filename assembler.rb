class Assembler
	def initialize
		@codes = []
		@labels = {}
		@macros = [
			"mov", "li", "lis", "addil", "addih",
			"call", "ret",
			"sll", "srl", "sla", "sra", "slli", "srli", "slai", "srai"
		]
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
		return :macro if @macros.include? head
		return :label if head[-1] == ":"
		return :native
	end

	def label_to_lmap
		address = 0
		@codes.map! do |code|
			case instruction_type_of(code)
			when :label
				@labels[code.split[0].chop] = address
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
			tmp = encode_line(code)
			ascii << tmp
			# p "000#{i} : "[-7,7] << tmp << code.gsub(/( |\n|\n|\r|\t)+/," ")
		end
		return ascii
	end 

	def bin2ascii str
		a = str.scan(/.{1,8}/)
		a = a.map { |s| ("0b" + s).to_i(0) }
		ret = a.inject("") { |out, i | out = i.chr + out}  
	end

	def remove_comment_of line
		if line.index("#")
			line = line[0...line.index("#")] << "\r\n"
		else
			line
		end
	end

	def expand_macro line
		line.delete! ","
		e = line.split
		case e[0]
		when "mov" # mov $d $s	-> add $d $s $0 0
			"add #{e[1]}, #{e[2]}, $r00, 0"
		when "li" # li $d imm -> addi $d $0 L imm
			"addi #{e[1]}, $r00, L, #{e[2]}"
		when "lis" # lis $d imm -> addi $d $0 H imm
			"addi #{e[1]}, $r00, H, #{e[2]}"
		when "addil" # addil $d $s imm -> addi $d $s L imm
			"addi #{e[1]}, #{e[2]}, L, #{e[3]}"
		when "addih" # addih $d $s imm -> addi $d $s H imm
			"addi #{e[1]}, #{e[2]}, H, #{e[3]}"
		when "call"
			[
				"addi  $r11, $r15, 4",
				"store $r11, $r14, 0",
				"addi  $r14, $r14, 4",
				"beq   $r00, $r00, #{e[1]}"
			]
		when "ret"
			[
				"subi  $r14, $r14, 4",
				"load  $r15, $r14, 0"
			]
	   	when "sll" # sll $d, $s, $s -> shift $d, $s, $s, 0, l, logic
	   		"shift #{e[1]}, #{e[2]}, #{e[3]}, 0, l, logic"
	   	when "srl" # srl $d, $s, $s -> shift $d, $s, $s, 0, r, logic
	   		"shift #{e[1]}, #{e[2]}, #{e[3]}, 0, r, logic"
	   	when "sla" # sla $d, $s, $s -> shift $d, $s, $s, 0, l, arith
	   		"shift #{e[1]}, #{e[2]}, #{e[3]}, 0, l, arith"
	   	when "sra" # sra $d, $s, $s -> shift $d, $s, $s, 0, r, arith
	   		"shift #{e[1]}, #{e[2]}, #{e[3]}, 0, r, arith"
	   	when "slli" # slli $d, $s, im -> shift $d, $s, $00, im, l, logic
	   		"shifti #{e[1]}, #{e[2]}, $r00, #{e[3]}, l, logic"
	   	when "srli" # srli $d, $s, im -> shift $d, $s, $00, im, r, logic
	   		"shifti #{e[1]}, #{e[2]}, $r00, #{e[3]}, r, logic"
	   	when "slai" # slai $d, $s, im -> shift $d, $s, $00, im, l, arith
	   		"shifti #{e[1]}, #{e[2]}, $r00, #{e[3]}, l, arith"
	   	when "srai" # srai $d, $s, im -> shift $d, $s, $00, im, r, arith
	   		"shifti #{e[1]}, #{e[2]}, $r00, #{e[3]}, r, arith"
		end
	end

	def encode_line line
		line.delete! ","
		e = line.split
		case e[0]
		when "add"
			"0000000" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << bin_of(:int, e[4], 13)
		when "addi"
			"0000001" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:LH, e[3]) << bin_of(:int, e[4], 16)
		when "sub"
			"0000010" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3])
		when "subi"
			"0000011" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << "0" << bin_of(:int, e[3], 16)
		when "not"
			"0000100" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "and"
			"0000110" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "or"
			"0001000" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "xor"
			"0001010" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "nand"
			"0001100" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "nor"
			"0001110" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "shift"
			"0010000" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << bin_of(:int, e[4], 5) << bin_of(:lr, e[5]) << bin_of(:la, e[6])
		when "shifti"
			"0010001" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << bin_of(:int, e[4], 5) << bin_of(:lr, e[5]) << bin_of(:la, e[6])

		when "fadd"
			"0100000" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "fsub"
			"0100010" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "fmul"
			"0100100" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "fdiv"
			"0100110" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "fsqrt"
			"0101000" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << "00000000000000000"
		when "ftoi"
			"0101010" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << "00000000000000000"
		when "itof"
			"0101100" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << "00000000000000000"
		when "fneg"
			"0101110" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << "00000000000000000"
		when "finv"
			"0110000" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << "00000000000000000"

		when "beq"
			"1000000" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "beqi"
			"1000001" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:lb, e[3])
		when "blt"
			"1000010" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "blti"
			"1000011" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:lb, e[3])
		when "bfeq"
			"1000100" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "bfeqi"
			"1000101" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:lb, e[3])
		when "bflt"
			"1000110" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "bflti"
			"1000111" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:lb, e[3])

		when "load"
			"1100000" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:int, e[3], 17)
		when "store"
			"1100010" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:int, e[3], 17)
		# when "fload"
		# 	"1100100" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3])
		# when "fstore"
		# 	"1100110" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3])
		when "loadr"
			"1101000" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		when "storer"
			"1101010" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3]) << "0000000000000"
		# when "floadr"
		# 	"1101100" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3])
		# when "fstorer"
		# 	"1101110" << bin_of(:reg, e[1]) << bin_of(:reg, e[2]) << bin_of(:reg, e[3])
		else
			raise "unknown opecode"
		end
	end

	def bin_of type, expr, option = nil
		case type
		when :reg
			sprintf "%04b", expr.slice(2,2).to_i
		when :int
			ret = sprintf "%0#{option}b", expr.to_i
			(expr.to_i > 0) ? ret : ret.sub("..","11")[-option,option]
		when :lr
			(expr == "l") ? "0" : "1"
		when :LH
			(expr == "L") ? "0" : "1"
		when :la
			(expr == "logic") ? "00" : "01"
		when :lb
			sprintf "%017b", @labels[expr]
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
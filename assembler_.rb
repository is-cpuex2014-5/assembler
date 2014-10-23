class Assembler
	def initialize
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
		src_ = "\tbeqi $r00 $r00 main\n"
		src.lines do |line|
			line = remove_comment_of line
			head = line.split[0]
			if @macros.include? head
				p expand_macro(line)
				src_ << expand_macro(line)
			elsif head
				p line
				src_ << line
			end
		end
		src = src_

		# 行の確定とラベルの保存
		address = 0
		labels = {}
		codes = ""
		src.lines do |line|
			next if line[0,2] == "\t."
			if line[0] == "\t" 
				# p "000#{address} : "[-7,7] << line
				address += 1
				codes << line
			else
				# p line
				@labels[line.split[0].chop] = address
			end
		end

		# 命令とレジスタとラベルの展開
		result = ""
		codes.lines.with_index do |line, i|
			if line[0] == "\t"
				p "000#{i} : "[-7,7] << self.encode_line(line) << line.gsub(/( |\n|\n|\r|\t)+/," ")
				result << self.encode_line(line)
			end
		end

		print bin2ascii(result)
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
			"\tadd #{e[1]}, #{e[2]}, $r00, 0\r\n"
		when "li" # li $d imm -> addi $d $0 L imm
			"\taddi #{e[1]}, $r00, L, #{e[2]}\r\n"
		when "lis" # lis $d imm -> addi $d $0 H imm
			"\taddi #{e[1]}, $r00, H, #{e[2]}\r\n"
		when "addil" # addil $d $s imm -> addi $d $s L imm
			"\taddi #{e[1]}, #{e[2]}, L, #{e[3]}\r\n"
		when "addih" # addih $d $s imm -> addi $d $s H imm
			"\taddi #{e[1]}, #{e[2]}, H, #{e[3]}\r\n"
		when "call"
			<<-EOS
\taddi  $r11, $r15, 4\r
\tstore $r11, $r14, 0\r
\taddi  $r14, $r14, 4\r
\tbeq   $r00, $r00, #{e[1]}\r
			EOS
		when "ret"
			<<-EOS
\tsubi  $r14, $r14, 4\r
\tload  $r15, $r14, 0\r
			EOS
   	when "sll" # sll $d, $s, $s -> shift $d, $s, $s, 0, l, logic
   		"\tshift #{e[1]}, #{e[2]}, #{e[3]}, 0, l, logic\r\n"
   	when "srl" # srl $d, $s, $s -> shift $d, $s, $s, 0, r, logic
   		"\tshift #{e[1]}, #{e[2]}, #{e[3]}, 0, r, logic\r\n"
   	when "sla" # sla $d, $s, $s -> shift $d, $s, $s, 0, l, arith
   		"\tshift #{e[1]}, #{e[2]}, #{e[3]}, 0, l, arith\r\n"
   	when "sra" # sra $d, $s, $s -> shift $d, $s, $s, 0, r, arith
   		"\tshift #{e[1]}, #{e[2]}, #{e[3]}, 0, r, arith\r\n"
   	when "slli" # slli $d, $s, im -> shift $d, $s, $00, im, l, logic
   		"\tshifti #{e[1]}, #{e[2]}, $r00, #{e[3]}, l, logic\r\n"
   	when "srli" # srli $d, $s, im -> shift $d, $s, $00, im, r, logic
   		"\tshifti #{e[1]}, #{e[2]}, $r00, #{e[3]}, r, logic\r\n"
   	when "slai" # slai $d, $s, im -> shift $d, $s, $00, im, l, arith
   		"\tshifti #{e[1]}, #{e[2]}, $r00, #{e[3]}, l, arith\r\n"
   	when "srai" # srai $d, $s, im -> shift $d, $s, $00, im, r, arith
   		"\tshifti #{e[1]}, #{e[2]}, $r00, #{e[3]}, r, arith\r\n"
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
class Assembler
	load 'settings.rb'
	# extend Settings

	def initialize
		@codes = []
		@labels = {}
		@macros = Settings.macros
		@instructions = Settings.instructions
	end

	def run filename
		src = File.read(filename)
		src = "\tbeqi\t$r00, $r00, main\n" + src
		@codes = src.split "\n"
		pre_process
		label_to_lmap
		ascii = encode_lines
                if $params['d']
                   p @labels
                end
                if $params['a']
                  print ascii
                else
                  print bin2ascii(ascii)
                end
	end

	def pre_process
		@codes.map! do |code|
			code = remove_comment_of code
			case instruction_type_of code
			when :blank
				nil
			when :label, :native
				code
			when :macro
				expand_macro code
			when :dot
				expand_dot code
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
		ascii = ""
		@codes.each_with_index do |code, i|
			ascii << encode_line(code)
                  if $params['d']
                    p sprintf "%04d : %08x %s", i, encode_line(code).to_i(2), code.gsub(/( |\n|\n|\r|\t)+/," ")
                  end
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

	def expand_dot line
		opes = (line.gsub ",", "").split
		case opes[0]
		when ".float"
			"dfloat #{opes[1]}"
		when ".integer"
			"dint #{opes[1]}"
		else
			nil
		end
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
			(expr == "arith") ? "00" : "01"
		when :imm05
			ret = sprintf "%05b", expr.to_i
			(expr.to_i > 0) ? ret : ret.sub("..","11")[-5,5]
		when :imm13
			ret = sprintf "%013b", expr.to_i
			(expr.to_i > 0) ? ret : ret.sub("..","11")[-13,13]
		when :imm16
                        if @labels[expr]
                          sprintf "%016b", @labels[expr]
                        else
			ret = sprintf "%016b", expr.to_i
			(expr.to_i > 0) ? ret : ret.sub("..","11")[-16,16]
                        end
		when :imm17
			if @labels[expr]
                          sprintf "%017b", @labels[expr]
			else
				ret = sprintf "%017b", expr.to_i
				(expr.to_i > 0) ? ret : ret.sub("..","11")[-17,17]
			end
		when :imm32
			ret = sprintf "%032b", expr.to_i
			(expr.to_i > 0) ? ret : ret.sub("..","11")[-32,32]
		when :immfl
			[expr.to_f].pack('g').bytes.map{|n| "%08b" % n}.join
		else
			raise "unknown operand type: #{type}"
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

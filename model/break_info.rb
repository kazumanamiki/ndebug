class BreakInfo
	# ブレイクポイント（行数）を管理する一覧
	attr_reader :list

	def initialize
		@list = Array.new
	end

	def add(file, line, index = -1)
		@list.insert(index, BreakPoint.new(file, line)) if find(file, line).nil?
	end

	def delete(index)
		@list.delete_at(index)
	end

	def check_break(file, line)
		return @list.find { |item| item.break?(file, line) }
	end

	def find(file, line)
		return @list.find { |item| item.equal?(file, line) }
	end

	def dump
		data = ""
		list.each { |break_point|
			data << "#{break_point.file}:#{break_point.line}\n"
		}
		return data
	end

	def load(data)
		data.each_line { |line|
			file, line = line.split(":")
			add(file, Integer(line.strip))
		}
	end
end

class BreakPoint

	attr_reader :file
	attr_reader :line
	attr_accessor :enable

	def initialize(file, line)
		@file = file
		@line = line.to_i
		@enable = true
	end

	def equal?(file, line)
		return ((@file == file) && (@line == line))
	end

	def break?(file, line)
		return false unless enable

		# ファイル名が"*"であれば行数のみの判定とする
		if @file == "*"
			return (@line == line)
		else
			return (file.include?(@file) &&(@line == line))
		end
	end
end
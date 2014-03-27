class WatcherInfo
	# 変数ウォッチを管理する一覧
	attr_reader :list

	def initialize
		@list = Array.new
	end

	def add(watch_exp, index = -1)
		@list.insert(index, watch_exp.strip)
	end

	def delete(index)
		@list.delete_at(index)
	end

	def dump
		data = ""
		list.each { |watch_exp|
			data << "#{watch_exp}\n"
		}
		return data
	end

	def load(data)
		data.each_line { |line|
			add(line.strip)
		}
	end
end
class DebugCommand

	attr_reader :command
	attr_reader :input

	def initialize(str)
		@input = str
		@command = str.strip.split(' ')
	end

	def is_empty
		return command.empty?
	end
end
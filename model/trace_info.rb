class TraceInfo

	# set_trace_func で取得できる情報
	attr_reader :event, :file, :line, :id, :binding, :classname
	# instance_eval で取得できる情報
	attr_reader :this_obj

	def initialize(event, file, line, id, binding, classname, this_obj)
		@event = event
		@file = file
		@line = line
		@id = id
		@binding = binding
		@classname = classname
		@this_obj = this_obj
	end

	def print
		# text = sprintf("LineInfo: %8s %s:%-2d %10s %8s\n", @event, @file, @line, @id, @classname)
		text = sprintf("%s:%-3d %s::%s(%s) bind:%s\n", @file, @line, @classname, @id, @event, @this_obj)
		NdebugPrinter.print text
	end
end

module TraceEvent
	_LINE = "line"
	_CALL = "call"
	_RETURN = "return"
	_C_CALL = "c-call"
	_C_RETURN = "c-return"
	_CLASS = "class"
	_END = "end"
	_RAISE = "raise"
end

module TraceClass
	_KERNEL = "Kernel"
	_CLASS = "Class"
	_MODULE = "Module"
	_IO = "IO"
end
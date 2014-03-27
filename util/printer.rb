require "singleton"

class NdebugPrinter
	include Singleton

	attr_accessor :io

	def self.print(text)
		NdebugPrinter.instance.io.printf(text) unless NdebugPrinter.instance.io.nil?
	end
end

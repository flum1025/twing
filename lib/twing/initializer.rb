require 'optparse'

class Twing
  class Initializer
    def initialize
      @optparse = OptionParser.new
      @options = {}
      @callbacks = {}
    end

    def add(key, *args, &block)
      @optparse.on(*args) { |v| @options[key] = v }
      @callbacks[key] = block if block
    end

    def init
      @optparse.parse!(ARGV)
      call(@options)
      @options
    end

    def call(options, root_options = options)
      options.each do |key, value|
        @callbacks[key].call(value, root_options) if @callbacks[key]
      end
    end
  end
end

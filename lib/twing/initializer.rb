require 'optparse'

class Twing
  class Initializer
    attr_reader :options

    def initialize(pre = false)
      @pre = pre
      @optparse = OptionParser.new
      @options = {}
      @callbacks = {}
    end

    def add(key, *args, &block)
      @optparse.on(*args) { |v| @options[key] = v }
      @callbacks[key] = block if block
    end

    def init(argv = ARGV, left = [])
      @optparse.parse(argv - left)
      call(@options)
      left
    rescue OptionParser::InvalidOption => e
      raise e unless @pre
      init(argv, left + e.args)
    end

    def call(options, root_options = options)
      options.each do |key, value|
        @callbacks[key].call(value, root_options) if @callbacks[key]
      end
    end
  end
end

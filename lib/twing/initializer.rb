require 'optparse'

class Twing
  class Initializer
    attr_reader :optparse, :options

    def initialize(pre = false)
      @pre = pre
      @optparse = OptionParser.new
      @optparse.version = Twing::VERSION
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
      e.args.each do |arg|
        next_item = argv[argv.index(arg) + 1]
        left += e.args
        left << next_item if !next_item.nil? && !next_item.start_with?(?-)
      end
      init(argv, left)
    end

    def call(options, root_options = options)
      options.each do |key, value|
        @callbacks[key].call(value, root_options) if @callbacks[key]
      end
    end
  end
end

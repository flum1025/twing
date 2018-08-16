class Twing
  module Modules
    class CustomLogger
      attr_reader :logger

      def initialize(logger, prefix)
        @logger = logger
        @prefix = prefix
      end

      [:fatal, :error, :warn, :info, :debug].each do |method|
        define_method method do |message|
          @logger.send(method, @prefix) { message }
        end
      end

      def method_missing(method, *args)
        @logger.send(method, *args)
      end
    end
  end
end

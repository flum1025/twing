require 'twing/utility/callback'

class Twing
  module Modules
    module Extend
      @@callbacks = Callback.new

      def callbacks
        @@callbacks
      end

      def on_init(&block)
        self.callbacks.add(:init, &block)
      end
    end

    def self.included(klass)
      klass.extend(Extend)
    end

    def init_modules
      self.class.callbacks.run(:init) do |callback|
        callback.call(self)
      end
    end
  end
end

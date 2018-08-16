require 'twing/utility/logger'

class Twing
  module Modules
    class Base
      attr_reader :logger, :setting, :app

      def initialize(app)
        @app = app
        @logger = CustomLogger.new(app.logger, self.class.to_s)
        @root_setting = app.setting
        @setting = app.setting.modules[self.class.to_s.downcase]
      end

      def on_message(*args)
        raise NotImplementedError.new("You must implement #{self.class}##{__method__}")
      end
    end
  end
end

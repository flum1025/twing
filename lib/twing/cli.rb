require 'twing/initializer'

class Twing
  class Cli
    SettingFileNotFound = Class.new(StandardError)

    attr_reader :initializer

    def initialize(app)
      @app = app
      @initializer = Initializer.new
      @setting = {}
      regist_default_options
    end

    def regist_default_options
      @initializer.add(:setting, '-s VALUES', '--setting VALUES', 'setting file path') do |file|
        @setting = Hashie::Mash.load(file)
      end
      @initializer.add(:debug, '-d', '--debug', 'debug mode') do
        @app.logger.level = Logger::DEBUG
      end
      @initializer.add(:log_file, '--log-file VALUES', 'log file') do |v, options|
        @app.logger = Logger.new(v, datetime_format: LOGGER_FORMAT)
        @app.logger.level = Logger::DEBUG if options[:debug]
      end
      @initializer.add(:streamer, '--streamer', 'start streamer') do
        @app.mode = :streamer
      end
      @initializer.add(:worker, '--worker VALUES', 'start worker') do
        @app.mode = :worker
      end
    end

    def parse
      cli_options = @initializer.init
      raise SettingFileNotFound if @setting.size.zero?
      setting = Hashie::Mash.new @setting.merge(cli_options)

      options = @setting.reduce({}) do |acc, (k, v)|
        key = k.to_sym
        acc[key] = v unless cli_options.keys.include?(key)
        acc
      end
      @initializer.call(options, setting)

      setting
    end
  end
end

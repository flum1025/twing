require 'hashie'
require 'twing/initializer'

class Twing
  class Cli
    SettingFileNotFound = Class.new(StandardError)

    attr_reader :initializer

    def initialize(app)
      @app = app
      @setting_loader = Initializer.new(true)
      @initializer = Initializer.new
      @setting = {}
      regist_setting_loader
      regist_initializer
    end

    def regist_setting_loader
      @setting_loader.add(:help, '-h', '--help', 'help') do
        puts @setting_loader.optparse.help
        puts @initializer.optparse.help.each_line.drop(1).join
        exit
      end
      @setting_loader.add(:setting, '-s VALUES', '--setting VALUES', 'setting file path') do |file|
        @setting = Hashie::Mash.load(file)
      end
    end

    def regist_initializer
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
      @initializer.add(:worker, '--worker', 'start worker') do
        @app.mode = :worker
      end
    end

    def parse
      argv = @setting_loader.init(ARGV)
      @initializer.init(argv)
      cli_options = @initializer.options
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

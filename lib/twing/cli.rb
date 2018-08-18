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

    def parse
      argv = @setting_loader.init(ARGV)

      raise SettingFileNotFound if @setting.size.zero?

      load_plugins
      @app.init_modules
      @initializer.init(argv)

      cli_options = @initializer.options
      setting = Hashie::Mash.new @setting.merge(cli_options)
      options = @setting.reduce({}) do |acc, (k, v)|
        key = k.to_sym
        acc[key] = v unless cli_options.keys.include?(key)
        acc
      end
      @initializer.call(options, setting)

      setting
    end

    private

    def load_plugins
      if @setting&.require.is_a?(Array)
        @setting.require.each { |file| require file }
      end
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
      @initializer.add(:debug, '-d', '--debug', 'debug mode')
      @initializer.add(:log_dir, '--log-dir VALUES', 'log dir')
      @initializer.add(:home_timeline, '--home-timeline', 'start streamer with home_timeline')
      @initializer.add(:filter, '--filter', 'start streamer with filter')
      @initializer.add(:user, '--user', 'start streamer with user')
      @initializer.add(:worker, '--worker', 'start worker')
      @initializer.add(:standalone, '--standalone', 'standalone mode')
      @initializer.add(:pouring, '-p', '--pouring VALUES', 'direct pouring tweet') do |v|
        Twing.after_init do |app|
          app.pouring(v)
          exit
        end
      end
    end
  end
end

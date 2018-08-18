require 'logger'
require 'twitter'
require 'twing/version'
require 'twing/modules'
require 'twing/receivers'
require 'twing/cli'
require 'twing/operating_mode'

class Twing
  include Modules
  include OperatingMode

  LOGGER_FORMAT = '%Y-%m-%d %H:%M:%S.%L '

  attr_accessor :logger
  attr_reader :receivers, :cli, :setting, :rest_client, :stream_client

  def initialize
    @receivers = Receivers.new
    @cli = Cli.new(self)
    @setting = @cli.parse
    @logger = generate_logger
    @receivers.init(self)

    @logger.debug("load plugins: #{@receivers.receivers}")

    @rest_client = Twitter::REST::Client.new(setting.twitter.api_key)
    @stream_client = Twitter::Streaming::Client.new(setting.twitter.api_key)
    after_init
  end

  def start
    raise ArgumentError, 'mode is empty' if mode.nil?
    logger.info("start mode=#{mode} standalone=#{setting.standalone}")
    send(mode)
  rescue Interrupt, SignalException
    # do nothing
  rescue Exception => ex
    backtrace = ex.backtrace.dup
    logger.error(<<~EOF)
      #{backtrace.shift}: #{ex.message} (#{ex.class})
      #{backtrace.join("\n")}
    EOF
  end

  private

  def generate_logger
    logdev = setting.log_dir ? File.join(setting.log_dir, "#{mode}.log") : STDOUT
    logger = Logger.new(logdev, datetime_format: LOGGER_FORMAT)
    logger.level = setting.debug ? Logger::DEBUG : Logger::INFO
    logger
  end

  def pouring(tweet_id)
    obj = client.status(tweet_id)
    delivery(obj)
  end

  def publish(data)
    logger.debug("Message publish #{data}")
    if setting.standalone
      delivery(data)
    else
      puts "queuing"
      #queue
    end
  end

  def delivery(data)
    logger.debug("Message delivery #{data}")
    @receivers.run do |receiver|
      receiver.on_message(data)
    end
  end
end

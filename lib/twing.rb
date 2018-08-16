require 'logger'
require 'twitter'
require 'twing/version'
require 'twing/modules'
require 'twing/receivers'
require 'twing/cli'

class Twing
  include Modules

  LOGGER_FORMAT = '%Y-%m-%d %H:%M:%S.%L '

  attr_accessor :logger, :mode
  attr_reader :receivers, :cli, :setting, :client

  def initialize
    @mode = :standalone
    @logger = Logger.new(STDOUT, datetime_format: LOGGER_FORMAT)
    @receivers = Receivers.new
    @cli = Cli.new(self)
    @setting = @cli.parse
    @receivers.init(self)
    @logger.debug("load plugins: #{@receivers.receivers}")
    @client = Twitter::REST::Client.new(setting.twitter.api_key)
    after_init
  end

  def start
    logger.info("start mode=#{mode}")
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

  def pouring(tweet_id)
    obj = client.status(tweet_id)
    publish(obj)
  end

  private

  def streamer
    options = setting.twitter.home_timeline_options.query.to_h
    options.merge!(count: options['timeline_count'])

    # loop do
    #   timeline = @client.home_timeline()
    # end
  rescue Twitter::Error::TooManyRequests => e
    sleep e.rate_limit.reset_in
    retry
  rescue Twitter::Error::ServerError, EOFError, Errno::EPIPE
    sleep 1
    retry
  end

  def worker

  end

  def standalone
    loop do
      publish(Twitter::Tweet.new(
        id: 1,
        text: 'test',
      ))
      sleep 1
    end
  end

  def publish(data)
    logger.debug("Message #{data}")
    @receivers.run do |receiver|
      receiver.on_message(data)
    end
  end
end

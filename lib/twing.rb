require 'logger'
require 'twitter'
require 'redis-objects'
require 'redis-namespace'
require 'twing/version'
require 'twing/modules'
require 'twing/receivers'
require 'twing/cli'
require 'twing/operating_mode'
require 'twing/queue'

class Twing
  include Modules
  include OperatingMode

  LOGGER_FORMAT = '%Y-%m-%d %H:%M:%S.%L '
  REDIS_KEY = 'home_timeline_streamer'

  attr_accessor :logger
  attr_reader :receivers, :cli, :setting, :rest_client, :stream_client, :redis

  def initialize
    @receivers = Receivers.new
    @cli = Cli.new(self)
    @setting = @cli.parse
    @logger = generate_logger
    @receivers.init(self)

    @logger.debug("load plugins: #{@receivers.receivers}")

    @rest_client = Twitter::REST::Client.new(setting.twitter.api_key)
    @stream_client = Twitter::Streaming::Client.new(setting.twitter.api_key)

    unless setting.standalone
      Redis.current = Redis::Namespace.new(
        setting.redis.namespace,
        :redis => Redis.new(setting.redis.config)
      )
      @redis = Redis.current
      @queue = Queue.new('queue', setting.redis.namespace)
    end

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
      body =
        case data
        when Twitter::Streaming::Event
          {
            event: object.name,
            source: object.source.to_h,
            target: object.target.to_h,
            target_object: object.target_object.to_h
          }.to_json
        when Twitter::Streaming::FriendList
          data.to_json
        else
          data.to_h.to_json
        end

      @queue.push({
        class: data.class.to_s,
        body: body
      }.to_json)
    end
  end

  def queue(data)
    redis
  end

  def delivery(data)
    logger.debug("Message delivery #{data}")
    @receivers.run do |receiver|
      receiver.on_message(data)
    end
  end
end

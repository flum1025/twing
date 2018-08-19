class Twing
  module OperatingMode
    private

    def mode
      return :home_timeline if setting.home_timeline
      return :filter if setting.filter
      return :user if setting.user
      return :worker if setting.worker
      return setting.mode.to_sym if setting.mode
    end

    def home_timeline
      options = setting.twitter.home_timeline_options.query.to_h
      options.merge!(count: options['timeline_count'])

      loop do
        logger.info('load new timeline')

        since_id = @cursor.get

        timeline = rest_client.home_timeline(
          since_id ? options.merge(since_id: since_id) : options
        ).each { |object| publish(object) }

        @cursor.set(timeline.first.id) unless timeline.first.nil?

        sleep setting.twitter.home_timeline_options.interval
      end
    rescue Twitter::Error::TooManyRequests => e
      sleep e.rate_limit.reset_in
      retry
    rescue Twitter::Error::ServerError, EOFError, Errno::EPIPE
      sleep 1
      retry
    end

    def worker
      @queue.process do |msg|
        logger.debug("Message subscribe #{msg}")
        object = msg2object(msg)
        delivery(object)
      end
    end

    def msg2object(msg)
      data = JSON.parse(msg)
      klass = Object.const_get(data['class'])
      klass.new(JSON.parse(data['body'], { symbolize_names: true }))
    end

    def user
      stream_client.user(setting.twitter.user_options || {}) do |object|
        publish(object)
      end
    end

    def filter
      stream_client.filter(setting.twitter.filter_options || {}) do |object|
        publish(object)
      end
    end
  end
end

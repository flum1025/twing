class Twing
  module OperatingMode
    private

    def mode
      return :home_timeline if setting.home_timeline
      return :filter if setting.filter
      return :user if setting.user
      return :worker if setting.worker
    end

    def home_timeline
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
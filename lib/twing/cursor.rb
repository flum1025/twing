class Twing
  class Cursor
    def initialize(key, use_redis = true)
      @key = key
      @use_redis = use_redis

      if @use_redis
        @redis = Redis.current
      else
        @cursor = nil
      end
    end

    def get
      return @redis.get(@key) if @use_redis
      @cursor
    end

    def set(value)
      return @redis.set(@key, value) if @use_redis
      @cursor = value
    end
  end
end

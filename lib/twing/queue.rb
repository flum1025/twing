class Twing
  class Queue
    def initialize(name, namespace)
      @name = name
      @redis = Redis.current
    end

    def push(data)
      @redis.rpush(@name, data)
    end

    def process
      loop do
        key, msg = @redis.blpop(@name, 0)
        yield msg if msg
      end
    end
  end
end

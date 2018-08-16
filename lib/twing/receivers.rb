class Twing
  class Receivers
    attr_reader :receivers, :instances

    def initialize
      @receivers, @instances = [], []
    end

    def add(receiver)
      @receivers << receiver
    end

    def init(app)
      @instances = @receivers.map do |receiver|
        receiver.new(app)
      end
    end

    def run(&block)
      @instances.each(&block)
    end
  end
end

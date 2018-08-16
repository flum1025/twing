class Callback
  def initialize
    @callbacks = Hash.new{|hash, key| hash[key] = []}
  end

  def add(type, &block)
    @callbacks[type] << block
  end

  def run(type)
    @callbacks[type].each do |callback|
      yield callback
    end
  end
end

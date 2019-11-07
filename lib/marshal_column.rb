class MarshalColumn
  attr_accessor :object_class

  def initialize(object_class = Object)
    @object_class = object_class
  end

  def dump(obj)
    return if obj.nil?

    unless obj.is_a?(object_class)
      raise ArgumentError, "Attribute was supposed to be a #{object_class}, but was a #{obj.class}. -- #{obj.inspect}"
    end

    Marshal.dump(obj)
  end

  def load(source)
    return object_class.new if object_class != Object && source.nil?
    return source unless source.is_a?(String)
    obj = Marshal.load(source)

    unless obj.is_a?(object_class) || obj.nil?
      raise ArgumentError, "Attribute was supposed to be a #{object_class}, but was a #{obj.class}"
    end
    obj ||= object_class.new if object_class != Object

    obj
  end
end

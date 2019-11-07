class InteractorResult
  def initialize(args)
    args.each do |key, value|
      (class << self; self; end).send(:attr_reader, key.to_sym)
      instance_variable_set("@#{key}", value) unless value.nil?
    end
  end
end

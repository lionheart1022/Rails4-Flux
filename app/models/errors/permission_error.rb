class PermissionError < StandardError
  def initialize(message = nil)
    super(message)
  end
end

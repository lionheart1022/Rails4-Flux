class GeodisCredentials
  attr_accessor :username
  attr_accessor :password
  attr_accessor :company_id

  def initialize(params = {})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end
end

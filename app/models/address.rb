class Address
  attr_accessor :country_code
  attr_accessor :state_code
  attr_accessor :city
  attr_accessor :zip_code
  attr_accessor :address_line1
  attr_accessor :address_line2

  def initialize(params = {})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def to_flat_string
    parts =
      [
        country_name,
        state_code,
        zip_code,
        city,
        address_line1,
        address_line2,
      ]

    parts
      .map { |part| part.to_s.strip }
      .reject { |part| part.empty? }
      .join(" ")
  end

  def country_name
    Country[country_code].try(:name)
  end
end

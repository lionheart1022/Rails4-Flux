class FedExStandardOvernightUSACarrierProduct < FedExStandardOvernightCarrierProduct
  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    return false if sender_country_code.blank? || destination_country_code.blank?

    sender_country_code.casecmp(destination_country_code) == 0 && sender_country_code.casecmp("us") == 0
  end

  def fed_ex_dimension_unit
    "IN"
  end

  def fed_ex_weight_unit
    "LB"
  end
end

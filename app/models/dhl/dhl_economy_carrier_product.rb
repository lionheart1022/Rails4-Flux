class DHLEconomyCarrierProduct < DHLGenericCarrierProduct

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    !import && is_international_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
  end

  def service(recipient: nil, sender: nil)
    economy_default_product_code(recipient: recipient, sender: sender)
  end

end

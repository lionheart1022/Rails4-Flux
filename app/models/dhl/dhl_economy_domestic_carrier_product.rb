class DHLEconomyDomesticCarrierProduct < DHLGenericCarrierProduct

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_domestic_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
  end

  def service(recipient: nil, sender: nil)
    DHLShipperLib::Codes::Services::ECONOMY_DOMESTIC
  end

end

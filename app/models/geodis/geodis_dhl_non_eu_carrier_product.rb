class GeodisDHLNonEUCarrierProduct < GeodisGenericDHLCarrierProduct
  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    !import && is_non_eu_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
  end
end

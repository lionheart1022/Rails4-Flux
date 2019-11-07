class TNTDomesticCarrierProduct < TNTGenericCarrierProduct

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_domestic = is_domestic_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
    is_import   = import
    return is_domestic && !is_import
  end

  def volume_weight(dimension: nil)
    factor = 4000
    volume_weight = Float((dimension.length * dimension.width * dimension.height)) / Float(factor)

    return volume_weight
  end

  def supports_track_and_trace?
    return true
  end

  def track_and_trace_has_complex_view?
    return false
  end

  def service
    return TNTShipperLib::ServiceCodes::Domestic::EXPRESS
  end
end

class TNTEconomyImportCarrierProduct < TNTGenericCarrierProduct

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_international = is_international_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
    is_import        = import

    return is_import && is_international
  end

  def import?
    true
  end

  # Calculates the volume weight for a package of certain dimensions
  #
  # @param dimension [PackageDimension] the dimensions from which to calculate the volume weight
  # @return [Float] The volume weight calculated for the specific product from the dimensions
  def volume_weight(dimension: nil)
    factor = self.custom_volume_weight_enabled ? self.volume_weight_factor : 4000
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
    return TNTShipperLib::ServiceCodes::International::ECONOMY_EXPRESS
  end
end

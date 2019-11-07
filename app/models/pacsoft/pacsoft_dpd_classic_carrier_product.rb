class PacsoftDpdClassicCarrierProduct < PacsoftGenericCarrierProduct

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_international = is_international_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
    is_import        = import

    return !is_import
  end

  def international?
    true
  end

  # The DPD product does not use volume weights
  def volume_weight(dimension: nil)
    return 0
  end

  def service
    return PacsoftShipperLib::ServiceCodes::PostDk::DPD_CLASSIC
  end

  def partner
    return PacsoftShipperLib::PartnerCodes::DPDDK
  end
end

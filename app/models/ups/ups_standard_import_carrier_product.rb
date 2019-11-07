class UPSStandardImportCarrierProduct < UPSGenericCarrierProduct
  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_international = is_international_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
    is_import        = import
    is_single_piece  = number_of_packages == 1

    return is_import && is_international && !is_single_piece
  end

  def import?
    true
  end

  def service
    return UPSShipperLib::ServiceCodes::International::STANDARD
  end
end

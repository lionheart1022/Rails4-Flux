class UPSSaverCarrierProduct < UPSGenericCarrierProduct

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    !import
  end

  def service
    return UPSShipperLib::ServiceCodes::International::SAVER
  end

end

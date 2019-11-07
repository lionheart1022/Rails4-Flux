class BringServicePackageCarrierProduct < BringGenericCarrierProduct

  def service
    BringShipperLib::Codes::Services::Standard::SERVICE_PAKKE
  end

  def return_service
    BringShipperLib::Codes::Services::Return::SERVICE_PAKKE
  end

  def supports_notifications?
    true
  end

end

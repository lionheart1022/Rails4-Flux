class UPSSaverReturnService1CarrierProduct < UPSSaverImportCarrierProduct
  def ups_return_service?
    true
  end

  def ups_return_service_code
    UPSShipperLib::ReturnServiceCodes::RS_1_ATTEMPT # UPS Return Service 1-Attempt (RS1)
  end
end

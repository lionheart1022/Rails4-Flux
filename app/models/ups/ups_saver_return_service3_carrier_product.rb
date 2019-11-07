class UPSSaverReturnService3CarrierProduct < UPSSaverImportCarrierProduct
  def ups_return_service?
    true
  end

  def ups_return_service_code
    UPSShipperLib::ReturnServiceCodes::RS_3_ATTEMPT # # UPS Return Service 3-Attempt (RS3)
  end
end

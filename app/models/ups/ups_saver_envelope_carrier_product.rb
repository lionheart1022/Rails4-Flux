class UPSSaverEnvelopeCarrierProduct < UPSSaverCarrierProduct
  def ups_letter?
    true
  end

  def packaging_code
    UPSShipperLib::PackagingCodes::LETTER
  end
end

class UPSExpressEnvelopeCarrierProduct < UPSExpressCarrierProduct
  def ups_letter?
    true
  end

  def packaging_code
    UPSShipperLib::PackagingCodes::LETTER
  end
end

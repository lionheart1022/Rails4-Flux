class UPSExpressDocumentCarrierProduct < UPSExpressCarrierProduct

  def packaging_code
    UPSShipperLib::PackagingCodes::DOCUMENT
  end

end

class DHLEconomyDocumentCarrierProduct < DHLGenericCarrierProduct

  def packaging_code
    DHLShipperLib::Codes::PackageTypes::EXPRESS_DOCUMENT
  end

  def service(recipient: nil, sender: nil)
    DHLShipperLib::Codes::Services::ECONOMY_DOCUMENT
  end
end

class DHLExpressDocumentCarrierProduct < DHLGenericCarrierProduct

  def packaging_code
    DHLShipperLib::Codes::PackageTypes::EXPRESS_DOCUMENT
  end

  def service(recipient: nil, sender: nil)
    within_eu = recipient.in_eu? && sender.in_eu?

    if within_eu
      DHLShipperLib::Codes::Services::EXPRESS_NONDUTIABLE
    else
      DHLShipperLib::Codes::Services::EXPRESS_DOCUMENT
    end
  end
end

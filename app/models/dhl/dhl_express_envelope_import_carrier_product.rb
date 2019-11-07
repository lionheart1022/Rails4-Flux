class DHLExpressEnvelopeImportCarrierProduct < DHLGenericCarrierProduct

  def import?
    true
  end

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    import
  end

  def packaging_code
    DHLShipperLib::Codes::PackageTypes::EXPRESS_DOCUMENT
  end

  def service(recipient: nil, sender: nil)
    DHLShipperLib::Codes::Services::EXPRESS_ENVELOPE
  end
end

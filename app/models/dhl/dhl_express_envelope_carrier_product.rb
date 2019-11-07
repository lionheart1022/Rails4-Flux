class DHLExpressEnvelopeCarrierProduct < DHLGenericCarrierProduct

  def packaging_code
    DHLShipperLib::Codes::PackageTypes::EXPRESS_DOCUMENT
  end

  def service(recipient: nil, sender: nil)
    DHLShipperLib::Codes::Services::EXPRESS_ENVELOPE
  end
end

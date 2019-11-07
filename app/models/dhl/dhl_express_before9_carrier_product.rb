class DHLExpressBefore9CarrierProduct < DHLGenericCarrierProduct
  def service(recipient: nil, sender: nil)
    within_eu = recipient.in_eu? && sender.in_eu?

    if within_eu
      DHLShipperLib::Codes::Services::EXPRESS_BEFORE_9_NONDUTIABLE
    else
      DHLShipperLib::Codes::Services::EXPRESS_BEFORE_9_DUTIABLE
    end
  end
end

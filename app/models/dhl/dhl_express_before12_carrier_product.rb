class DHLExpressBefore12CarrierProduct < DHLGenericCarrierProduct
  def service(recipient: nil, sender: nil)
    within_eu = recipient.in_eu? && sender.in_eu?

    if within_eu
      DHLShipperLib::Codes::Services::EXPRESS_BEFORE_12_NONDUTIABLE
    else
      DHLShipperLib::Codes::Services::EXPRESS_BEFORE_12_DUTIABLE
    end
  end
end

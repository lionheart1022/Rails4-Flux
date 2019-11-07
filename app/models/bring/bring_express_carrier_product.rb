class BringExpressCarrierProduct < BringGenericCarrierProduct

  def service
    BringShipperLib::Codes::Services::Standard::EKSPRESS
  end

  def return_service
    BringShipperLib::Codes::Services::Return::EKSPRESS
  end

  def supports_notifications?
    true
  end

end

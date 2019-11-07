class BringBpakkeCarrierProduct < BringGenericCarrierProduct

  def service
    BringShipperLib::Codes::Services::Standard::BPAKKE
  end

  def return_service
    BringShipperLib::Codes::Services::Return::BPAKKE
  end

  def supports_notifications?
    true
  end

end

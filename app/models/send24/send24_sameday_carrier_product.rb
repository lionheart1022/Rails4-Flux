class Send24SamedayCarrierProduct < Send24GenericCarrierProduct

  def service
    Send24ShipperLib::Services::SAMEDAY
  end

end

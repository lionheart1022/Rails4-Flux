class BringCarryonHomeCarrierProduct < BringGenericCarrierProduct

  def service
    BringShipperLib::Codes::Services::Standard::CARRYON_HOME
  end

  def return_service
    BringShipperLib::Codes::Services::Return::CARRYON_HOME
  end

end

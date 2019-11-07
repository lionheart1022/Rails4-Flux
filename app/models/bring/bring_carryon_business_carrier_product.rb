class BringCarryonBusinessCarrierProduct < BringGenericCarrierProduct

  def service
    BringShipperLib::Codes::Services::Standard::CARRYON_BUSINESS
  end

  def return_service
    BringShipperLib::Codes::Services::Return::CARRYON_BUSINESS
  end

end

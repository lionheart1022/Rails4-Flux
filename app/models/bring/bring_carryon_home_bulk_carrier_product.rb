class BringCarryonHomeBulkCarrierProduct < BringGenericCarrierProduct

  def service
    BringShipperLib::Codes::Services::Standard::CARRYON_HOME_BULK
  end

  def return_service
    BringShipperLib::Codes::Services::Return::CARRYON_HOME_BULK
  end

end

class BringCarryonHomeBulkHomeCarrierProduct < BringGenericCarrierProduct

  def service
    BringShipperLib::Codes::Services::Standard::CARRYON_HOME_BULK_HOME
  end

end

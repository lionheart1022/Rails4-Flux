class Send24PrivateCarrierProduct < Send24GenericCarrierProduct

  def service
    Send24ShipperLib::Services::PRIVATE
  end

end

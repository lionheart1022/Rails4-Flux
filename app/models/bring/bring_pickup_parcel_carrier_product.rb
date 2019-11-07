class BringPickupParcelCarrierProduct < BringGenericCarrierProduct
  def service
    BringShipperLib::Codes::Services::Standard::PICKUP_PARCEL
  end

  def return_service
    raise "not supported"
  end
end

class DAONatXpressCarrierProduct < DAOGenericCarrierProduct

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_domestic     = is_domestic_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
    is_import       = import
    is_single_piece = number_of_packages == 1

    return !is_import && is_domestic && is_single_piece
  end

  def service
    return
  end

  def dao_tracking_status_map
    { "09" => TrackingLib::States::DELIVERED }
  end
end

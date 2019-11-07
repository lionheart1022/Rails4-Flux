class DAOPakkeshopCarrierProduct < DAOGenericCarrierProduct

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
    {
      "3" => TrackingLib::States::EXCEPTION,
      "11" => TrackingLib::States::IN_TRANSIT,
      "12" => TrackingLib::States::IN_TRANSIT,
      "13" => TrackingLib::States::IN_TRANSIT,
      "15" => TrackingLib::States::IN_TRANSIT,
      "16" => TrackingLib::States::IN_TRANSIT,
      "25" => TrackingLib::States::IN_TRANSIT,
      "26" => TrackingLib::States::IN_TRANSIT,
      "29" => TrackingLib::States::IN_TRANSIT,
      "32" => TrackingLib::States::DELIVERED,
      "41" => TrackingLib::States::EXCEPTION,
      "42" => TrackingLib::States::IN_TRANSIT,
      "48" => TrackingLib::States::IN_TRANSIT,
      "51" => TrackingLib::States::DELIVERED,
      "52" => TrackingLib::States::IN_TRANSIT,
      "86" => TrackingLib::States::IN_TRANSIT
    }
  end
end

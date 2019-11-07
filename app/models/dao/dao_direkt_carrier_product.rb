class DAODirektCarrierProduct < DAOGenericCarrierProduct

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
      "9"  => TrackingLib::States::EXCEPTION,
      "10" => TrackingLib::States::IN_TRANSIT,
      "11" => TrackingLib::States::DELIVERED,
      "13" => TrackingLib::States::DELIVERED,
      "12" => TrackingLib::States::EXCEPTION,
      "21" => TrackingLib::States::EXCEPTION,
      "24" => TrackingLib::States::DELIVERED,
      "31" => TrackingLib::States::DELIVERED,
      "32" => TrackingLib::States::EXCEPTION,
      "33" => TrackingLib::States::EXCEPTION,
      "36" => TrackingLib::States::EXCEPTION,
      "37" => TrackingLib::States::EXCEPTION,
      "38" => TrackingLib::States::EXCEPTION,
      "51" => TrackingLib::States::EXCEPTION,
      "55" => TrackingLib::States::EXCEPTION,
      "58" => TrackingLib::States::EXCEPTION,
      "61" => TrackingLib::States::EXCEPTION,
      "62" => TrackingLib::States::EXCEPTION,
      "63" => TrackingLib::States::EXCEPTION,
      "64" => TrackingLib::States::EXCEPTION,
      "65" => TrackingLib::States::EXCEPTION,
      "66" => TrackingLib::States::EXCEPTION,
      "67" => TrackingLib::States::DELIVERED,
      "69" => TrackingLib::States::EXCEPTION,
      "72" => TrackingLib::States::IN_TRANSIT,
      "80" => TrackingLib::States::EXCEPTION,
      "85" => TrackingLib::States::EXCEPTION,
      "86" => TrackingLib::States::IN_TRANSIT
    }
  end
end

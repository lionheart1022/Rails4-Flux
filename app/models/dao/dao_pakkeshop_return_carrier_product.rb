class DAOPakkeshopReturnCarrierProduct < DAOGenericCarrierProduct
  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_domestic = is_domestic_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
    is_import = import
    is_single_piece = number_of_packages == 1

    !is_import && is_domestic && is_single_piece
  end

  def service
    nil
  end
end

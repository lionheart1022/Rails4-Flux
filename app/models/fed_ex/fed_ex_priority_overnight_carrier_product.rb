class FedExPriorityOvernightCarrierProduct < FedExGenericCarrierProduct
  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_domestic = is_domestic_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
    is_export = !import

    is_domestic && is_export
  end

  def service
    FedExShipperLib::ServiceTypes::PRIORITY_OVERNIGHT
  end
end

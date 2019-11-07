class DHLSubGenericCarrierProduct < CarrierProduct

  def price_document_class
    DHLSubPriceDocument
  end

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_import = import

    return !is_import
  end

  def supports_shipment_auto_booking?
    true
  end

  def supports_automatic_tracking?
    false
  end

  def supports_shipment_between_countries?(sender_country_code: nil, destination_country_code: nil)
    return is_international_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
  end

  def import?
    false
  end

  def dutiable_required?
    false
  end

  def ignore_dutiable?
    false
  end

  # Calculates the volume weight for a package of certain dimensions
  #
  # @param dimension [PackageDimension] the dimensions from which to calculate the volume weight
  # @return [Float] The volume weight calculated for the specific product from the dimensions
  def volume_weight(dimension: nil)
    factor = 5000
    volume_weight = Float((dimension.length * dimension.width * dimension.height)) / Float(factor)

    return volume_weight
  end

  def supports_track_and_trace?
    return true
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    shipment = Shipment.find(shipment_id)
    shipment.waiting_for_booking(comment: 'In queue to be booked with DHL')
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    request = DHLSubCarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end

  def supports_shipment_retry_awb_document?
    return false
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    return "https://nolp.dhl.de/nextt-online-public/set_identcodes.do?idc=#{awb}"
  end

  # @return [TNTShipperLib::ServiceCodes]
  def service
    raise StandardError.new, "Abstract class. Not implemented"
  end
end

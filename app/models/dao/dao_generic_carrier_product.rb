class DAOGenericCarrierProduct < CarrierProduct

  def supports_shipment_auto_booking?
    return true
  end

  def supports_track_and_trace?
    return true
  end

  def supports_test_mode?
    true
  end

  def supports_shipment_between_countries?(sender_country_code: nil, destination_country_code: nil)
    return is_international_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    # mark shipment as waiting for booking
    shipment = Shipment.find(shipment_id)
    shipment.waiting_for_booking(comment: 'In queue to be booked with DAO')
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    request = DAOCarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end

  def retry_awb_document(company_id: nil, shipment_id: nil)
    request = DAOCarrierProductAutobookRequest.find_request_for_shipment(company_id: company_id, shipment_id: shipment_id)

    # mark shipment as fetching awb
    shipment = Shipment.find(shipment_id)
    shipment.fetching_awb_document(comment: 'Fetching AWB document', linked_object: request)
    EventManager.handle_event(event: Shipment::Events::FETCHING_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })

    # fetch awb
    request.enqueue_retry_awb_document_job
  end

  def supports_shipment_retry_awb_document?
    return true
  end

  def supports_shipment_retry_consignment_note?
    return false
  end

  def service
    raise StandardError.new, "Abstract class. Not implemented"
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    return DAOShipperLib::TRACKANDTRACE_ENDPOINT + "stregkode=#{awb}"
  end

  def track_shipment(shipment: nil)
    DAOTrackingLib.new(shipment).track
  end

  def dao_tracking_status_map
    raise StandardError.new, "Abstract class. Not implemented"
  end
end

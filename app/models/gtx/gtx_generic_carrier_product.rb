class GTXGenericCarrierProduct < CarrierProduct

  def price_document_class
    GTXPriceDocument
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

  def supports_test_mode?
    true
  end

  def supports_return_label?
    false
  end

  def import?
    false
  end

  def dutiable_required?
    false
  end

  def volume_weight(dimension: nil)
    factor = 5000
    volume_weight = Float((dimension.length * dimension.width * dimension.height)) / Float(factor)

    return volume_weight
  end

  def supports_track_and_trace?
    true
  end

  def supports_shipment_retry_awb_document?
    false
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    shipment = Shipment.find(shipment_id)
    shipment.waiting_for_booking(comment: 'In queue to be booked with GTX')
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    request = GTXCarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    user_id = get_credentials[:user_id]
    "http://www.pacsoftonline.com/ext.po.dk.dk.track?key=#{user_id}&reference=#{shipment.unique_shipment_id}"
  end

  def service
    raise StandardError.new, "Abstract class. Not implemented"
  end

  def gtx_shipment_type
    "NonDocument"
  end
end

class Send24GenericCarrierProduct < CarrierProduct

  def price_document_class
    raise StandardError.new("Send24 pricing not implemented")
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
    false
  end

  def supports_return_label?
    true
  end

  def import?
    false
  end

  def dutiable_required?
    false
  end

  def supports_track_and_trace?
    true
  end

  def supports_shipment_retry_awb_document?
    false
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    shipment = Shipment.find(shipment_id)
    shipment.waiting_for_booking(comment: 'In queue to be booked with Send24')
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    request = Send24CarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end

  # def track_shipment(shipment: nil)
  #   awb         = shipment.awb
  #   credentials = self.get_credentials
  #   credentials = Send24TrackingLib::Credentials.new(username: credentials[:username], password: credentials[:password])

  #   tracking_lib = Send24TrackingLib.new
  #   trackings    = tracking_lib.track(credentials: credentials, awb: awb)
  #   return trackings
  # end

  def track_and_trace_url(awb: nil, shipment: nil)
    "https://send24.com/track?#{awb}"
  end

  def service
    raise StandardError.new, "Abstract class. Not implemented"
  end
end

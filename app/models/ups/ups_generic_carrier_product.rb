require "ups"

class UPSGenericCarrierProduct < CarrierProduct

  def price_document_class
    UPSPriceDocument
  end

  def supports_shipment_auto_booking?
    return true
  end

  def import?
    false
  end

  def volume_weight(dimension: nil)
    Float(dimension.length * dimension.width * dimension.height) / UPS::VOLUME_WEIGHT_FACTOR
  end

  def supports_track_and_trace?
    true
  end

  def track_and_trace_has_complex_view?
    true
  end

  def track_and_trace_view
    "components/shared/carrier_products/ups"
  end

  def supports_automatic_tracking?
    true
  end

  def supports_auto_pickup?
    true
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    # mark shipment as waiting for booking
    shipment = Shipment.find(shipment_id)
    shipment.waiting_for_booking(comment: 'In queue to be booked with UPS')
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    request = UPSCarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end

  # @return [UPSShipperLib::ServiceCodes]
  def service
    raise StandardError.new, "Abstract class. Not implemented"
  end

  # Only document carrier products specify another code
  def packaging_code
    UPSShipperLib::PackagingCodes::CUSTOMER_SUPPLIED_PACKAGE
  end

  def ups_documents_only?
    false
  end

  def ups_letter?
    false
  end

  def ups_return_service?
    false
  end

  def ups_return_service_code
  end

  def track_shipment(shipment: nil)
    awb         = shipment.awb
    credentials = self.get_credentials
    credentials = UPSTrackingLib::Credentials.new(access_token: credentials[:access_token], company: credentials[:company], password: credentials[:password])

    tracking_lib = UPSTrackingLib.new
    trackings    = tracking_lib.track(credentials: credentials, awb: awb)
    return trackings
  end

  def prebook_step?
    true
  end

  def perform_prebook_step(shipment)
    UPSPrebookCheck.run(shipment)
  end

end

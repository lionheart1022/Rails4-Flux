require "tnt"

class TNTGenericCarrierProduct < CarrierProduct
  def price_document_class
    TNTPriceDocument
  end

  def supports_shipment_between_countries?(sender_country_code: nil, destination_country_code: nil)
    return is_international_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
  end

  def supports_shipment_auto_booking?
    return true
  end

  def import?
    false
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
    shipment.waiting_for_booking(comment: 'In queue to be booked with TNT')
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    request = TNTCarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end

  def supports_shipment_retry_awb_document?
    return true
  end

  def retry_awb_document(company_id: nil, shipment_id: nil)
    request = TNTCarrierProductAutobookRequest.find_request_for_shipment(company_id: company_id, shipment_id: shipment_id)

    # mark shipment as fetching awb
    shipment = Shipment.find(shipment_id)
    shipment.fetching_awb_document(comment: 'Fetching AWB document', linked_object: request)
    EventManager.handle_event(event: Shipment::Events::FETCHING_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })

    # fetch awb
    request.enqueue_retry_awb_document_job
  end

  def supports_shipment_retry_consignment_note?
    return true
  end

  def retry_consignment_note(company_id: nil, shipment_id: nil)
    request = TNTCarrierProductAutobookRequest.find_request_for_shipment(company_id: company_id, shipment_id: shipment_id)

    # mark shipment as fetching consignment note
    shipment = Shipment.find(shipment_id)
    shipment.fetching_consignment_note(comment: 'Fetching consignment note', linked_object: request)
    EventManager.handle_event(event: Shipment::Events::FETCHING_CONSIGNMENT_NOTE, event_arguments: { shipment_id: shipment.id })

    # fetch awb
    request.enqueue_retry_consignment_note_job
  end

  def minimized_reference_field(reference: nil, shipment_id: nil, scoped_customer_id: nil)
    full_reference = "#{reference} / #{scoped_customer_id}-#{shipment_id}"

    # TNT limits the CUSTOMERREF (customer user reference) field to 24 characters.
    # `reference` is limited to 18 characters in the shipment form and with the added customer and shipment ID it can exceed 24 characters.
    if full_reference.length <= 24
      full_reference
    else
      # Let's limit the reference to 24 characters just to be safe, even though it should be max. 18 characters.
      "#{reference}".slice(0, 24)
    end
  end

  def track_shipment(shipment: nil)
    awb         = shipment.awb
    credentials = self.get_credentials
    credentials = TNTTrackingLib::Credentials.new(company: credentials[:company], password: credentials[:password])

    tracking_lib = TNTTrackingLib.new
    trackings    = tracking_lib.track(credentials: credentials, awb: awb)
    return trackings
  end

  # @return [TNTShipperLib::ServiceCodes]
  def service
    raise StandardError.new, "Abstract class. Not implemented"
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    TNT.track_and_trace_url(awb: awb)
  end
end

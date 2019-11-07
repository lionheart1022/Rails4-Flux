require "dsv"

class DSVGenericCarrierProduct < CarrierProduct
  def supports_shipment_auto_booking?
    true
  end

  def import?
    false
  end

  def supports_automatic_tracking?
    false
  end

  def supports_track_and_trace?
    true
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    DSV.track_and_trace_url(awb: awb)
  end

  def supports_test_mode?
    true
  end

  def supports_auto_pickup?
    true
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    Shipment.find(shipment_id).waiting_for_booking(comment: "In queue to be booked with DSV")
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment_id })
    DSVCarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end

  def service
    raise "Override in subclass"
  end

  def dsv_label_text
    raise "Override in subclass"
  end

  def zip_code_to_dsv_location_identifier(_zip_code)
    raise "Override in subclass"
  end
end

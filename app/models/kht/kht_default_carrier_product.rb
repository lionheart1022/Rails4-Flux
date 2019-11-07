require "kht"

class KHTDefaultCarrierProduct < CarrierProduct
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

  def supports_test_mode?
    true
  end

  def supports_auto_pickup?
    true
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    KHT.track_and_trace_url(awb: awb)
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    Shipment.find(shipment_id).waiting_for_booking(comment: "In queue to be booked with KHT")
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment_id })
    KHTCarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end
end

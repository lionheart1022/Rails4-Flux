require "bring"

class BringGenericCarrierProduct < CarrierProduct

  def supports_shipment_auto_booking?
    true
  end

  def supports_track_and_trace?
    true
  end

  def supports_test_mode?
    true
  end

  def supports_return_label?
    false
  end

  def supports_notifications?
    true
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    # mark shipment as waiting for booking
    shipment = Shipment.find(shipment_id)
    shipment.waiting_for_booking(comment: 'In queue to be booked with Bring')
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    request = BringCarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end

  def volume_weight(dimension: nil)
    factor = 4000
    volume_weight = Float((dimension.length * dimension.width * dimension.height)) / Float(factor)

    return volume_weight
  end

  def service
    raise StandardError.new, "Abstract class. Not implemented"
  end

  # Specifics are overridden in subclasses
  def return_service
    BringShipperLib::Codes::Services::Return::CARRYON_HOME
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    Bring.track_and_trace_url(awb: awb)
  end
end

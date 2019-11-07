require "post_nord"

class UnifaunGenericCarrierProduct < CarrierProduct
  WEIGHT_OF_ONE_CUBIC_METER = 280 # 1 m^3 ~ 280 kg
  VOLUME_WEIGHT_FACTOR = 100**3 / Float(WEIGHT_OF_ONE_CUBIC_METER)

  def price_document_class
    UnifaunPriceDocument
  end

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_import = import

    return !is_import
  end

  def supports_delivery_instructions?
    true
  end

  def supports_shipment_auto_booking?
    true
  end

  def supports_automatic_tracking?
    true
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

  def supports_track_and_trace?
    true
  end

  def supports_shipment_retry_awb_document?
    false
  end

  def auto_book_request_class
    UnifaunCarrierProductAutobookRequestV2
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    shipment = Shipment.find(shipment_id)
    shipment.waiting_for_booking(comment: 'In queue to be booked with Unifaun')
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    request = auto_book_request_class.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end

  def volume_weight(dimension: nil)
    Float(dimension.volume) / VOLUME_WEIGHT_FACTOR
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    user_id = get_credentials[:user_id]
    PostNord.track_and_trace_url(awb: awb)
  end

  def postnord_pallet?
    false
  end

  def postnord_sender_partners
    []
  end

  def track_shipment(shipment: nil)
    UnifaunAutoTracking.track_shipment(awb: shipment.awb)
  rescue UnifaunAutoTracking::ResponseServerError
    Rails.logger.error "exception=UnifaunAutoTracking::ResponseServerError shipment_id=#{shipment.id}"
    nil
  rescue UnifaunAutoTracking::BlankAWBError => e
    ExceptionMonitoring.report!(e, context: { shipment_id: shipment.id, awb: shipment.awb })
    nil
  rescue UnifaunAutoTracking::UnexpectedResponseBody => e
    ExceptionMonitoring.report!(e, context: { shipment_id: shipment.id, awb: shipment.awb, original_exception: e.original_exception, response_body: e.body })
    nil
  end

  def service
    raise StandardError.new, "Abstract class. Not implemented"
  end
end

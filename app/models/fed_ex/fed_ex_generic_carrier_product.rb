class FedExGenericCarrierProduct < CarrierProduct
  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    supports_shipment_between_countries?(
      sender_country_code: sender_country_code,
      destination_country_code: destination_country_code
    )
  end

  def supports_shipment_between_countries?(sender_country_code: nil, destination_country_code: nil)
    is_international_shipment?(
      sender_country_code: sender_country_code,
      destination_country_code: destination_country_code
    )
  end

  def supports_shipment_auto_booking?
    true
  end

  def supports_automatic_tracking?
    true
  end

  def import?
    false
  end

  def service
    fail NotImplementedError, "service not set"
  end

  def supports_track_and_trace?
    true
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    "https://www.fedex.com/apps/fedextrack/?tracknumbers=#{awb}"
  end

  def track_shipment(shipment: nil)
    tracking_lib = FedExTrackingLib.new(api_host: fed_ex_api_host)
    tracking_lib.track(credentials: fed_ex_credentials, awb: shipment.awb)
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    shipment = Shipment.find(shipment_id)
    shipment.waiting_for_booking(comment: 'In queue to be booked with FedEx')
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    FedExCarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(
      company_id: company_id,
      customer_id: customer_id,
      shipment_id: shipment_id
    )
  end

  def fed_ex_credentials
    FedExCredentials.new(
      get_credentials.fetch(:developer_key),
      get_credentials.fetch(:developer_password),
      get_credentials.fetch(:account_number),
      get_credentials.fetch(:meter_number)
    )
  end

  def fed_ex_api_host
    ENV.fetch("FED_EX_HOST", "https://wsbeta.fedex.com:443")
  end

  def fed_ex_dimension_unit
    "CM"
  end

  def fed_ex_weight_unit
    "KG"
  end

  def fed_ex_international_document?
    false
  end
end

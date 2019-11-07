class GLSGenericCarrierProduct < CarrierProduct

  def price_document_class
    GLSPriceDocument
  end

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_import = import

    return !is_import
  end

  def supports_shipment_auto_booking?
    return true
  end

  def supports_automatic_tracking?
    true
  end

  def supports_test_mode?
    true
  end

  def supports_return_label?
    true
  end

  def gls_deliver_to_parcelshop?
    false
  end

  def gls_is_private_service?
    false
  end

  def gls_shop_return_product?
    false
  end

  def supports_automatic_tracking?
    true
  end

  def supports_shipment_between_countries?(sender_country_code: nil, destination_country_code: nil)
    return is_international_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
  end

  def import?
    false
  end

  def dutiable_required?
    false
  end

  def supports_override_credentials?
    true
  end

  def override_credentials_class
    GLSCarrierProductCredential
  end

  def supports_track_and_trace?
    return true
  end

  def track_and_trace_url(awb: nil, shipment: nil)
    "https://gls-group.eu/IE/en/parcel-tracking?match=#{awb}"
  end

  def auto_book_request_class
    GLSCarrierProductAutobookRequest
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    shipment = Shipment.find(shipment_id)
    shipment.waiting_for_booking(comment: 'In queue to be booked with GLS')
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    request = auto_book_request_class.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
  end

  def supports_shipment_retry_awb_document?
    return false
  end

  def track_shipment(shipment: nil)
    credentials_hash = get_credentials
    override_carrier_credential = carrier.override_credentials_class.find_by(target: carrier, owner: shipment.customer)

    gls_tracking_credentials =
      if override_carrier_credential
        GLSTrackingLib::Credentials.new(
          username: override_carrier_credential.username || credentials_hash[:username],
          password: override_carrier_credential.password || credentials_hash[:password],
        )
      else
        GLSTrackingLib::Credentials.new(
          username: credentials_hash[:username],
          password: credentials_hash[:password],
        )
      end

    GLSTrackingLib.new.track(credentials: gls_tracking_credentials, awb: shipment.awb)
  end

  def service
    raise StandardError.new, "Abstract class. Not implemented"
  end
end

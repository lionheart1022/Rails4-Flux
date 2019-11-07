class GeodisGenericCarrierProduct < CarrierProduct
  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    !import
  end

  def import?
    false
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

  def supports_auto_pickup?
    geodis_template_with_pickup.present?
  end

  def supports_track_and_trace?
    false
  end

  def supports_shipment_retry_awb_document?
    false
  end

  def auto_book_shipment(company_id: nil, customer_id: nil, shipment_id: nil)
    shipment = Shipment.find(shipment_id)

    shipment.waiting_for_booking(comment: "In queue to be booked with DHL")
    EventManager.handle_event(event: Shipment::Events::WAITING_FOR_BOOKING, event_arguments: { shipment_id: shipment.id })

    request = GeodisCarrierProductAutobookRequest.create_carrier_product_autobook_request_and_enqueue_job(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
    request
  end

  def geodis_credentials
    GeodisCredentials.new(
      username: get_credentials.fetch(:username),
      password: get_credentials.fetch(:password),
      company_id: get_credentials.fetch(:company_id),
    )
  end

  def geodis_template_with_pickup
    get_credentials[:template_with_pickup]
  end

  def geodis_template_without_pickup
    get_credentials[:template_without_pickup]
  end
end

class UnifaunCarrierProductAutobookRequestV2 < CarrierProductAutobookRequest
  def autobook_shipment
    started

    shipment.booking_initiated(comment: "Booking with PostNord", linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOKING_INITIATED, event_arguments: { shipment_id: shipment_id })

    carrier_product = shipment.carrier_product
    customer_carrier_product = CustomerCarrierProduct.find_customer_carrier_product(customer_id: customer_id, carrier_product_id: carrier_product.id)

    booking_request = UnifaunShipmentHTTPRequest.new(shipment)
    booking_request.test = customer_carrier_product.test

    booking_response = booking_request.book_shipment!

    booking_response.generate_temporary_awb_pdf_file do |awb_pdf_path|
      shipment.create_or_update_awb_asset_from_local_file(file_path: awb_pdf_path, linked_object: self)
    end

    shipment.book(awb: booking_response.awb_no, comment: "Booking completed", linked_object: self)

    EventManager.handle_event(event: Shipment::Events::AUTOBOOK, event_arguments: { shipment_id: shipment_id })

    shipment.update!(shipment_errors: nil) # Clear (possibly previous) errors
    completed
  rescue UnifaunShipmentHTTPResponse::ParameterError, UnifaunShipmentHTTPResponse::UnauthorizedError => e
    handle_user_exception(e)
  rescue UnifaunShipmentHTTPResponse::UnknownError => e
    ExceptionMonitoring.report(e, context: {
      carrier_product_autobook_request_id: id,
      shipment_id: shipment_id,
      request_body: booking_request.request_body,
      response_code: e.response.status,
      response_body: e.response.body,
    })

    handle_generic_exception(e)
  rescue => e
    ExceptionMonitoring.report(e, context: {
      carrier_product_autobook_request_id: id,
      shipment_id: shipment_id,
    })

    handle_generic_exception(e)
  end

  private

  def handle_user_exception(exception)
    error(exception: exception, info: exception.message)
    shipment.booking_fail(comment: "Automatic booking failed", errors: exception.as_shipment_errors, linked_object: self)
    EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_PROBLEM, event_arguments: { shipment_id: shipment_id })
  end

  def handle_generic_exception(exception)
    error(exception: exception, info: exception.message)
    shipment.booking_fail(comment: "An unknown error occurred while performing automatic booking", linked_object: self)
    EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_PROBLEM, event_arguments: { shipment_id: shipment_id })
  end
end

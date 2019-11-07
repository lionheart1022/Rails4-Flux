class GeodisCarrierProductAutobookRequest < CarrierProductAutobookRequest
  def autobook_shipment
    started

    shipment.booking_initiated(comment: "Booking with Geodis", linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOKING_INITIATED, event_arguments: { shipment_id: shipment_id })

    carrier_product = shipment.carrier_product
    customer_carrier_product = CustomerCarrierProduct.find_customer_carrier_product(customer_id: customer_id, carrier_product_id: carrier_product.id)

    booking_request = GeodisBookingRequest.build_from_shipment(shipment)
    booking_request.test = customer_carrier_product.test

    booking_response = booking_request.book_shipment!

    if booking_response.error?
      return handle_booking_response_error(booking_response)
    end

    booking_response.generate_temporary_awb_pdf_file do |awb_pdf_path|
      shipment.create_or_update_awb_asset_from_local_file(file_path: awb_pdf_path, linked_object: self)
    end

    warnings =
      if booking_response.warning.present?
        [BookingLib::Errors::APIError.new(code: "CF-GW-W01", description: booking_response.warning)]
      else
        []
      end

    shipment.book(awb: booking_response.awb_no, comment: "Booking completed", linked_object: self, warnings: warnings)
    EventManager.handle_event(event: Shipment::Events::AUTOBOOK, event_arguments: { shipment_id: shipment_id })

    if shipment.pickup_relation && shipment.pickup_relation.auto?
      if booking_response.pickup_error?
        shipment.pickup_relation.report_problem(comment: booking_response.warning)
      else
        shipment.pickup_relation.book(comment: "The related shipment was successfully booked")
      end
    end

    completed
  rescue => exception
    handle_generic_exception(exception)
  end

  private

  def handle_generic_exception(exception)
    error(exception: exception, info: exception.message)
    shipment.booking_fail(comment: "An unknown error occurred while performing automatic booking", linked_object: self)
    EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_PROBLEM, event_arguments: { shipment_id: shipment_id })

    if shipment.pickup_relation && shipment.pickup_relation.auto?
      shipment.pickup_relation.report_problem(comment: "The related shipment-booking failed")
    end
  end

  def handle_booking_response_error(booking_response)
    shipment_errors = [Shipment::Errors::GenericError.new(code: "CF-GW-E01", description: booking_response.message)]

    error(exception: nil, info: booking_response.message)
    shipment.booking_fail(comment: booking_response.message, errors: shipment_errors, linked_object: self)
    EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_PROBLEM, event_arguments: { shipment_id: shipment_id })

    if shipment.pickup_relation && shipment.pickup_relation.auto?
      shipment.pickup_relation.report_problem(comment: "The related shipment-booking failed")
    end
  end
end

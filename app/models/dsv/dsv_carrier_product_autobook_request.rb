class DSVCarrierProductAutobookRequest < CarrierProductAutobookRequest
  def autobook_shipment
    started

    shipment.booking_initiated(comment: "Booking with DSV", linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOKING_INITIATED, event_arguments: { shipment_id: shipment_id })

    customer_carrier_product = CustomerCarrierProduct.find_by!(customer_id: customer_id, carrier_product_id: shipment.carrier_product_id)

    booking_result = DSVBooking.perform!(shipment, test: customer_carrier_product.test)

    booking_result.generate_temporary_awb_pdf_file do |awb_pdf_path|
      shipment.create_or_update_awb_asset_from_local_file(file_path: awb_pdf_path, linked_object: self)
    end

    shipment.book(awb: booking_result.awb, comment: "Booking completed", linked_object: self)
    EventManager.handle_event(event: Shipment::Events::AUTOBOOK, event_arguments: { shipment_id: shipment_id })

    shipment.update!(shipment_errors: nil) # Clear (possibly previous) errors
    completed
  rescue => exception
    ExceptionMonitoring.report(exception, context: { carrier_product_autobook_request_id: id, shipment_id: shipment_id })
    handle_generic_exception(exception)
  end

  def handle_generic_exception(exception)
    error(exception: exception, info: exception.message)
    shipment.booking_fail(comment: "An unknown error occurred while performing automatic booking", linked_object: self)
    EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_PROBLEM, event_arguments: { shipment_id: shipment_id })

    if shipment.pickup_relation && shipment.pickup_relation.auto?
      shipment.pickup_relation.report_problem(comment: "The related shipment-booking failed")
    end
  end
end

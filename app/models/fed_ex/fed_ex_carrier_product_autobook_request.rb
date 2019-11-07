class FedExCarrierProductAutobookRequest < CarrierProductAutobookRequest
  def autobook_shipment
    self.started

    shipment = Shipment.find(self.shipment_id)

    shipment.booking_initiated(comment: 'Booking with FedEx', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOKING_INITIATED, event_arguments: { shipment_id: shipment.id })

    carrier_product = shipment.carrier_product

    fed_ex_shipper = FedExShipperLib.new(api_host: carrier_product.fed_ex_api_host)

    booking = fed_ex_shipper.book_shipment(
      credentials: carrier_product.fed_ex_credentials,
      shipment: shipment,
      sender: shipment.sender,
      recipient: shipment.recipient,
      carrier_product: carrier_product
    )

    booking.combined_awb_pdf do |awb_pdf_path|
      shipment.create_or_update_awb_asset_from_local_file(
        file_path: awb_pdf_path,
        linked_object: self
      )
    end

    shipment.book(
      awb: booking.awb,
      comment: 'Booking completed',
      linked_object: self,
      warnings: booking.warnings
    )

    EventManager.handle_event(
      event: booking_event(shipment),
      event_arguments: {shipment_id: shipment.id}
    )

    self.completed
  rescue => exception
    self.handle_error(exception: exception)
  end

  private

  def booking_event(shipment)
    if shipment.shipment_warnings.empty?
      Shipment::Events::AUTOBOOK
    else
      Shipment::Events::AUTOBOOK_WITH_WARNINGS
    end
  end
end

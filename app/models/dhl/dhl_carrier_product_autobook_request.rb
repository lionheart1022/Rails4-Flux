class DHLCarrierProductAutobookRequest < CarrierProductAutobookRequest

  def autobook_shipment
    self.started

    customer = Customer.find(self.customer_id)
    shipment = Shipment.find(self.shipment_id)

    shipment.booking_initiated(comment:'Booking with DHL', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOKING_INITIATED, event_arguments: { shipment_id: shipment.id })

    carrier_product = shipment.carrier_product

    dhl_credentials     = DHLShipperLib::Credentials.new(
      company: carrier_product.get_credentials[:company],
      password: carrier_product.get_credentials[:password],
      account: carrier_product.get_credentials[:account]
    )

    dgr_mapping = DHLDangerousGoodsMapping.new_from_shipment(shipment)
    dgr_mapping.perform_mapping!

    dhl_shipper = DHLShipperLib.new
    booking     = dhl_shipper.book_shipment(credentials: dhl_credentials, shipment: shipment, sender: shipment.sender, recipient: shipment.recipient, carrier_product: carrier_product, dgr_mapping: dgr_mapping)
    Rails.logger.debug "\nDHLBooking:\n#{booking.inspect}\n"

    shipment.create_or_update_awb_asset_from_local_file(file_path: booking.awb_file_path, linked_object: self) if booking.awb_file_path.present?
    shipment.create_or_update_consignment_note_asset_from_local_file(file_path: booking.consignment_note_file_path, linked_object: self) if booking.consignment_note_file_path.present?

    dhl_shipper.remove_temporary_files(booking)
    shipment.book(awb: booking.awb, comment: 'Booking completed', linked_object: self)

    event = Shipment::Events::AUTOBOOK
    EventManager.handle_event(event: event, event_arguments: {shipment_id: shipment.id})

    if shipment.pickup_relation && shipment.pickup_relation.auto?
      pickup_request = DHLPickupRequest.build(credentials: dhl_credentials, pickup: shipment.pickup_relation, shipment: shipment)

      begin
        pickup_response = pickup_request.book_pickup!
      rescue DHLPickupRequest::UserValidationError => e
        shipment.pickup_relation.report_problem(comment: "Pickup could not be booked at DHL. Reason: #{e.message}")
      rescue => e
        shipment.pickup_relation.report_problem(comment: "Pickup could not be booked at DHL")

        ExceptionMonitoring.report!(e)
      else
        if pickup_response.success?
          shipment.pickup_relation.book(comment: "Pickup successfully booked at DHL (confirmation number: #{pickup_response.confirmation_number})")
        elsif pickup_response.error?
          shipment.pickup_relation.report_problem(comment: pickup_response.error_message)
        end
      end
    end

    self.completed
  rescue => exception
    self.handle_error(exception: exception)
  end

end

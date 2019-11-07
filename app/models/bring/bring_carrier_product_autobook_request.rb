class BringCarrierProductAutobookRequest < CarrierProductAutobookRequest

  def autobook_shipment
    self.started

    customer = Customer.find(self.customer_id)
    shipment = Shipment.find(self.shipment_id)

    shipment.booking_initiated(comment:'Booking with Bring', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOKING_INITIATED, event_arguments: { shipment_id: shipment.id })

    carrier_product          = shipment.carrier_product
    customer_carrier_product = CustomerCarrierProduct.find_customer_carrier_product(customer_id: self.customer_id, carrier_product_id: carrier_product.id)
    is_test                  = customer_carrier_product.test

    credentials = carrier_product.get_credentials
    bring_credentials = BringShipperLib::Credentials.new(
      user_id:         credentials[:user_id],
      customer_number: credentials[:customer_number],
      api_key:         credentials[:api_key],
    )

    bring_shipper = BringShipperLib.new
    booking = bring_shipper.book_shipment(credentials: bring_credentials, shipment: shipment, sender: shipment.sender, recipient: shipment.recipient, carrier_product: carrier_product, test: is_test)

    shipment.create_or_update_awb_asset_from_local_file(file_path: booking.awb_file_path, linked_object: self)

    bring_shipper.remove_temporary_files(booking)
    shipment.book(awb: booking.awb, comment: 'Booking completed', linked_object: self)

    event = Shipment::Events::AUTOBOOK
    EventManager.handle_event(event: event, event_arguments: {shipment_id: shipment.id})

    self.completed
  rescue => exception
    self.handle_error(exception: exception)
  end

end

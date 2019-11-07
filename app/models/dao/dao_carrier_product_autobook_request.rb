class DAOCarrierProductAutobookRequest < CarrierProductAutobookRequest
  def autobook_shipment
    self.started

    # load data
    customer = Customer.find(self.customer_id)
    shipment = Shipment.find(self.shipment_id)

    customer_carrier_product = CustomerCarrierProduct.find_customer_carrier_product(customer_id: customer.id, carrier_product_id: shipment.carrier_product_id)
    is_test                  = customer_carrier_product.test

    dao_shipper       = DAOShipperLib.new

    # mark shipment as booking initiated
    shipment.booking_initiated(comment:'Booking with DAO', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOKING_INITIATED, event_arguments: { shipment_id: shipment.id })

    # credentials
    carrier_product = shipment.carrier_product
    credentials     = DAOShipperLib::Credentials.new(password: carrier_product.get_credentials[:password], account: carrier_product.get_credentials[:account])

    dao_shipment = DAOShipperLib::Shipment.new({
      shipment_id:        shipment.unique_shipment_id,
      shipping_date:      shipment.shipping_date,
      number_of_packages: shipment.number_of_packages,
      package_dimensions: shipment.package_dimensions,
      description:        shipment.description,
      carrier_product:    shipment.carrier_product,
      parcelshop_id:      shipment.parcelshop_id
    })

    booking     = dao_shipper.book_shipment(credentials: credentials, shipment: dao_shipment, sender: shipment.sender, recipient: shipment.recipient, test: is_test)

    # Save barcode for awb document retrievel
    #
    self.data[:barcode] = booking.barcode
    self.data[:shop_id] = booking.shop_id if booking.shop_id
    self.save!

    shipment.book_without_awb_document(awb:booking.awb, comment: 'Booking succeeded', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })

    shipment.fetching_awb_document(linked_object: self)
    EventManager.handle_event(event: Shipment::Events::FETCHING_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })

    awb_document_path = dao_shipper.get_awb_document(credentials: credentials, booking: booking)

    shipment.create_or_update_awb_asset_from_local_file(file_path: awb_document_path, linked_object: self)
    dao_shipper.remove_temporary_file(file_path: awb_document_path)

    shipment.book(awb: booking.barcode, comment: 'Booking completed', linked_object: self)

    event = Shipment::Events::AUTOBOOK
    EventManager.handle_event(event: event, event_arguments: {shipment_id: shipment.id})

    self.completed
  rescue => exception
    Rails.logger.error(exception.inspect)
    self.handle_error(exception: exception)
  end

  def retry_awb_document
    shipment          = Shipment.find(self.shipment_id)
    carrier_product   = shipment.carrier_product
    credentials       = DAOShipperLib::Credentials.new(password: carrier_product.get_credentials[:password], account: carrier_product.get_credentials[:account])

    dao_shipper       = DAOShipperLib.new

    booking           = DAOShipperLib::Booking.new(barcode: self.data[:barcode])
    awb_document_path = dao_shipper.get_awb_document(credentials: credentials, booking: booking)

    shipment.create_or_update_awb_asset_from_local_file(file_path: awb_document_path, linked_object: self)
    dao_shipper.remove_temporary_file(file_path: awb_document_path)

    shipment.book(awb: booking.barcode, comment: 'Booking completed', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::RETRY_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })

    self.completed
  rescue => exception
    Rails.logger.error(exception.inspect)
    self.handle_error(exception: exception)
  end

end

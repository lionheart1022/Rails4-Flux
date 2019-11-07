class PacsoftCarrierProductAutobookRequest < CarrierProductAutobookRequest
  # PUBLIC API
  class << self
    def create_carrier_product_autobook_request(company_id: nil, customer_id: nil, shipment_id: nil)
      request = nil

      PacsoftCarrierProductAutobookRequest.transaction do
        request = super
        request.save!
      end

      return request
    end
  end

  # PUBLIC INSTANCE API
  def autobook_shipment
    # update state
    self.started

    # load data
    customer = Customer.find(self.customer_id)
    shipment = Shipment.find(self.shipment_id)

    # mark shipment as booking initiated
    shipment.booking_initiated(comment:'Booking with pacsoft', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOKING_INITIATED, event_arguments: { shipment_id: shipment.id })

    # credentials
    carrier_product = shipment.carrier_product
    credentials     = PacsoftShipperLib::Credentials.new(company: carrier_product.get_credentials[:company], password: carrier_product.get_credentials[:password], account: carrier_product.get_credentials[:account])

    # convert data
    shipper_lib_sender, shipper_lib_recipient = [shipment.sender, shipment.recipient].map do |contact|
      PacsoftShipperLib::Contact.new({
        contact_id:    contact.id,
        company_name:  contact.company_name,
        attention:     contact.attention,
        email:         contact.email,
        phone_number:  contact.phone_number,
        address_line1: contact.address_line1,
        address_line2: contact.address_line2,
        address_line3: contact.address_line3,
        zip_code:      contact.zip_code,
        city:          contact.city,
        country_code:  contact.country_code
      })
    end

    shipper_lib_shipment = PacsoftShipperLib::Shipment.new({
      shipment_id:             shipment.unique_shipment_id,
      created_at:              shipment.created_at,
      shipping_date:           shipment.shipping_date,
      number_of_packages:      shipment.number_of_packages,
      package_dimensions:      shipment.package_dimensions,
      dutiable:                shipment.dutiable,
      customs_amount:          shipment.customs_amount,
      customs_currency:        shipment.customs_currency,
      customs_code:            shipment.customs_code,
      description:             shipment.description,
      linkprintkey:            SecureRandom.hex,
      carrier_product:         carrier_product,
      carrier_product_service: shipment.carrier_product_service,
      carrier_product_supports_auto_book_delivery: shipment.carrier_product_supports_auto_book_delivery?,
      reference:               shipment.reference
    })

    # perform booking with tnt
    shipper_lib = PacsoftShipperLib.new
    shipper_lib.book_shipment(credentials: credentials, shipment: shipper_lib_shipment, sender: shipper_lib_sender, recipient: shipper_lib_recipient)

    # mark shipment as fully booked
    shipment.book(awb: shipper_lib_shipment.shipment_id, external_awb_asset: shipper_lib_shipment.linkprintkey, comment: 'Booking completed', linked_object: self)

    # email notification
    EventManager.handle_event(event: Shipment::Events::AUTOBOOK, event_arguments: { shipment_id: shipment.id })

    # completed
    self.completed
  rescue => exception
    self.handle_error(exception: exception)
  end

end

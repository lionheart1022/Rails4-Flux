class TNTCarrierProductAutobookRequest < CarrierProductAutobookRequest
  # PUBLIC API
  class << self
    def create_carrier_product_autobook_request(company_id: nil, customer_id: nil, shipment_id: nil)
      request = nil

      TNTCarrierProductAutobookRequest.transaction do
        request = super
        request.data = {
          tnt_access_id: nil,
          tnt_data: nil
        }
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
    shipment.booking_initiated(comment:'Booking with TNT', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOKING_INITIATED, event_arguments: { shipment_id: shipment.id })

    # credentials
    carrier_product = shipment.carrier_product
    credentials     = TNTShipperLib::Credentials.new(company: carrier_product.get_credentials[:company], password: carrier_product.get_credentials[:password], account: carrier_product.get_credentials[:account])

    # options
    tnt_shipping_options = TNTShipperLib::ShippingOptions.new(service: carrier_product.service, import: carrier_product.import?)

    # convert data
    tnt_sender, tnt_recipient = [shipment.sender, shipment.recipient].map do |contact|
    phone_number              = contact.phone_number

      if phone_number.present?
        phone_number_filtered   = phone_number.scan(/[^\-\+\(\) \/]+/).join("")
        phone_number_truncated  = phone_number_filtered.truncate(16, omission: '')
      else
        phone_number_truncated = ""
      end

      # ensure there's data in both dial code and phone number
      # dial code has limit of 7 digits, phone number 9 digits
      if phone_number_truncated.length > 7
        phone_number_dial_code  = phone_number_truncated[0..6]
        phone_number_number     = phone_number_truncated[7..-1]
      elsif phone_number_truncated.length > 1
        half_size = Integer(phone_number_truncated.length / 2)
        phone_number_dial_code  = phone_number_truncated[0..(half_size-1)]
        phone_number_number     = phone_number_truncated[half_size..-1]
      else
        # invalid phone number so just set something that will validate
        phone_number_dial_code  = "00"
        phone_number_number     = "0"
      end

      new_contact = TNTShipperLib::Contact.new({
        company_name:           contact.company_name,
        attention:              contact.attention,
        email:                  contact.email,
        phone_number_dial_code: phone_number_dial_code,
        phone_number_number:    phone_number_number,
        address_line1:          contact.address_line1,
        address_line2:          contact.address_line2,
        address_line3:          contact.address_line3,
        zip_code:               contact.zip_code,
        city:                   contact.city,
        country_code:           contact.country_code,
        state_code:             contact.state_code
      })

      new_contact
    end

    collection_contact =
      if shipment.pickup_relation && shipment.pickup_relation.contact
        shipment.pickup_relation.contact
      else
        shipment.sender
      end

    tnt_collection_info = TNTShipperLib::CollectionInfo.new_from_contact(collection_contact)

    if shipment.pickup_relation
      tnt_collection_info.book = true
      tnt_collection_info.from_time = shipment.pickup_relation.from_time
      tnt_collection_info.to_time = shipment.pickup_relation.to_time
      tnt_collection_info.instructions = shipment.pickup_relation.description
    end

    scoped_customer_id = shipment.unique_shipment_id.split('-')[1]
    tnt_shipment       = TNTShipperLib::Shipment.new({
      shipment_id:         shipment.unique_shipment_id,
      shipping_date:       shipment.shipping_date,
      number_of_packages:  shipment.number_of_packages,
      package_dimensions:  shipment.package_dimensions,
      dutiable:            shipment.dutiable,
      customs_amount:      shipment.customs_amount,
      customs_currency:    shipment.customs_currency,
      customs_code:        shipment.customs_code,
      description:         shipment.description,
      reference:           shipment.reference,
      minimized_reference: carrier_product.minimized_reference_field(reference: shipment.reference, scoped_customer_id: scoped_customer_id, shipment_id: shipment.shipment_id),
    })

    # perform booking with tnt
    tnt_shipper = TNTShipperLib.new
    booking     = tnt_shipper.book_shipment(credentials: credentials, shipment: tnt_shipment, sender: tnt_sender, recipient: tnt_recipient, collection_info: tnt_collection_info, shipping_options: tnt_shipping_options)

    # mark shipment as booked
    shipment.book_without_awb_document(awb:booking.awb, comment: 'Booking succeeded', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })

    shipment.fetching_awb_document(linked_object: self)
    EventManager.handle_event(event: Shipment::Events::FETCHING_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })

    # mark pickup as booked, if auto enabled
    if shipment.pickup_relation && shipment.pickup_relation.auto?
      if booking.booking_reference.present?
        shipment.pickup_relation.book_and_set_bll(bll: booking.booking_reference, comment: "Pickup booked at TNT with booking ref.: #{booking.booking_reference}")
      else
        if Rails.env.development?
          shipment.pickup_relation.comment(comment: "No BLL was returned by TNT probably because we're using non-production credentials")
        else
          shipment.pickup_relation.report_problem(comment: "No BLL was returned by TNT probably because we're using non-production credentials")
        end
      end
    end

    # save access id
    self.data[:tnt_access_id] = booking.access_id
    self.save!

    # get awb document
    booking_awb = tnt_shipper.get_awb_document(booking: booking)

    # pull out awb document and add to shipment
    shipment.create_or_update_awb_asset_from_local_file(file_path: booking_awb.awb_file_path, linked_object: self)

    # mark as waiting for consignment note
    shipment.book_without_consignment_note(awb: booking.awb, comment: 'Waiting for consignment note', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_CONSIGNMENT_NOTE, event_arguments: { shipment_id: shipment.id })

    shipment.fetching_consignment_note(linked_object: self)
    EventManager.handle_event(event: Shipment::Events::FETCHING_CONSIGNMENT_NOTE, event_arguments: { shipment_id: shipment.id })

    # get consignment note
    booking_consignment_note = tnt_shipper.get_consignment_note_document(booking: booking_awb)

    # pull out consignment note and add to shipment
    shipment.create_or_update_consignment_note_asset_from_local_file(file_path: booking_consignment_note.consignment_note_file_path, linked_object: self)

    # delete any temp files
    tnt_shipper.remove_temporary_files(booking: booking_consignment_note)

    # mark shipment as fully booked
    shipment.book(awb: booking.awb, comment: 'Booking completed', linked_object: self)

    # email notification
    EventManager.handle_event(event: Shipment::Events::AUTOBOOK, event_arguments: {shipment_id: shipment.id})

    # completed
    self.completed
  rescue => exception
    self.handle_error(exception: exception)
  end

  def retry_awb_document
    # load data
    shipment = Shipment.find(self.shipment_id)

    # create booking
    booking = TNTShipperLib::Booking.new(access_id: self.data[:tnt_access_id], shipment_id: shipment.unique_shipment_id)

    # get awb document
    tnt_shipper = TNTShipperLib.new
    booking_awb = tnt_shipper.get_awb_document(booking: booking)

    # pull out awb document and add to shipment
    shipment.create_or_update_awb_asset_from_local_file(file_path: booking_awb.awb_file_path, linked_object: self)

    # get consignment note
    booking_consignment_note = tnt_shipper.get_consignment_note_document(booking: booking_awb)

    # pull out consignment note and add to shipment
    shipment.create_or_update_consignment_note_asset_from_local_file(file_path: booking_consignment_note.consignment_note_file_path, linked_object: self)

    # delete any temp files
    tnt_shipper.remove_temporary_files(booking: booking_consignment_note)

    # mark shipment as fully booked
    shipment.book(awb: booking.awb, comment: 'Booking completed', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::RETRY_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })

    # completed
    self.completed
  rescue => exception
    case exception.class.to_s
      when BookingLib::Errors::AwbDocumentFailedException.to_s
        Rails.logger.error(exception.error_code)
        Rails.logger.error(exception.errors)

        self.error(info: exception.human_friendly_text)
        if (exception.class.to_s == BookingLib::Errors::AwbDocumentFailedException.to_s) && (exception.error_code == TNTShipperLib::Errors::CREATE_AWB_PDF_FAILED)
          self.data[:tnt_error] = exception.error_code
          self.data[:tnt_data]  = exception.data
          self.save!
        end

        shipment = Shipment.find(self.shipment_id)
        shipment.book_without_awb_document(awb: shipment.awb, comment: 'Adding TNT AWB document failed', linked_object: self)
        EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })
      when Shipment::Errors::CreateAwbAssetException.to_s
        Rails.logger.error(exception)

        self.error(info: exception)

        shipment = Shipment.find(self.shipment_id)
        shipment.book_without_awb_document(awb: shipment.awb, comment: 'Adding TNT AWB document failed', linked_object: self)
        EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })
      when BookingLib::Errors::ConsignmentNoteFailedException.to_s
        Rails.logger.error(exception.error_code)
        Rails.logger.error(exception.errors)

        self.error(info: exception.human_friendly_text)
        if (exception.class.to_s == BookingLib::Errors::ConsignmentNoteFailedException.to_s) && (exception.error_code == TNTShipperLib::Errors::CREATE_CONSIGNMENT_PDF_FAILED)
          self.data[:tnt_error] = exception.error_code
          self.data[:tnt_data]  = exception.data
          self.save!
        end

        shipment = Shipment.find(self.shipment_id)
        shipment.book_without_consignment_note(awb: shipment.awb, comment: 'Adding TNT consignment note failed', linked_object: self)
        EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_CONSIGNMENT_NOTE, event_arguments: { shipment_id: shipment.id })
      when Shipment::Errors::CreateConsignmentNoteAssetException.to_s
        Rails.logger.error(exception)

        self.error(info: exception)

        shipment = Shipment.find(self.shipment_id)
        shipment.book_without_consignment_note(awb: shipment.awb, comment: 'Adding TNT consignment note failed', linked_object: self)
        EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_CONSIGNMENT_NOTE, event_arguments: { shipment_id: shipment.id })
      when BookingLib::Errors::BookingLibException.to_s
        Rails.logger.error(exception.error_code)
        Rails.logger.error(exception.errors)

        self.error(info: exception.human_friendly_text)
        shipment = Shipment.find(self.shipment_id)
        shipment.book_without_awb_document(awb: shipment.awb, comment: 'Adding TNT AWB document failed', linked_object: self)
        EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })
      else
        self.error(info: error)
        shipment = Shipment.find(self.shipment_id)
        shipment.book_without_awb_document(awb: shipment.awb, comment: 'Adding TNT AWB document failed', linked_object: self)
        EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_AWB_DOCUMENT, event_arguments: { shipment_id: shipment.id })
    end
  end

  def retry_consignment_note
    # load data
    shipment = Shipment.find(self.shipment_id)

    # create booking
    booking = TNTShipperLib::Booking.new(access_id: self.data[:tnt_access_id], shipment_id: shipment.unique_shipment_id)

    # get consignment note
    tnt_shipper = TNTShipperLib.new
    booking_consignment_note = tnt_shipper.get_consignment_note_document(booking: booking)

    # pull out consignment note and add to shipment
    shipment.create_or_update_consignment_note_asset_from_local_file(file_path: booking_consignment_note.consignment_note_file_path, linked_object: self)

    # delete any temp files
    tnt_shipper.remove_temporary_files(booking: booking_consignment_note)

    # mark shipment as fully booked
    shipment.book(awb: booking.awb, comment: 'Booking completed', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::RETRY_CONSIGNMENT_NOTE, event_arguments: { shipment_id: shipment.id })

    # completed
    self.completed
  rescue => exception
    case exception.class.to_s
      when BookingLib::Errors::ConsignmentNoteFailedException.to_s
        Rails.logger.error(exception.error_code)
        Rails.logger.error(exception.errors)

        self.error(info: exception.human_friendly_text)
        if (exception.class.to_s == BookingLib::Errors::ConsignmentNoteFailedException.to_s) && (exception.error_code == TNTShipperLib::Errors::CREATE_CONSIGNMENT_PDF_FAILED)
          self.data[:tnt_error] = exception.error_code
          self.data[:tnt_data]  = exception.data
          self.save!
        end

        shipment = Shipment.find(self.shipment_id)
        shipment.book_without_consignment_note(awb: shipment.awb, comment: 'Adding TNT consignment note failed', linked_object: self)
        EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_CONSIGNMENT_NOTE, event_arguments: { shipment_id: shipment.id })
      when Shipment::Errors::CreateConsignmentNoteAssetException.to_s
        Rails.logger.error(exception)

        self.error(info: exception)

        shipment = Shipment.find(self.shipment_id)
        shipment.book_without_consignment_note(awb: shipment.awb, comment: 'Adding TNT consignment note failed', linked_object: self)
        EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_CONSIGNMENT_NOTE, event_arguments: { shipment_id: shipment.id })
      when BookingLib::Errors::BookingLibException.to_s
        Rails.logger.error(exception.error_code)
        Rails.logger.error(exception.errors)

        self.error(info: exception.human_friendly_text)
        shipment = Shipment.find(self.shipment_id)
        shipment.book_without_consignment_note(awb: shipment.awb, comment: 'Adding TNT consignment note failed', linked_object: self)
        EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_CONSIGNMENT_NOTE, event_arguments: { shipment_id: shipment.id })
      else
        self.error(info: exception)
        shipment = Shipment.find(self.shipment_id)
        shipment.book_without_consignment_note(awb: shipment.awb, comment: 'Adding TNT consignment note failed', linked_object: self)
        EventManager.handle_event(event: Shipment::Events::BOOK_WITHOUT_CONSIGNMENT_NOTE, event_arguments: { shipment_id: shipment.id })
    end
  end

  # hooks to save exception errors when exception is raised
  def handle_consignment_exceptions(exception)
    if (exception.class.to_s == BookingLib::Errors::ConsignmentNoteFailedException.to_s) && (exception.error_code == TNTShipperLib::Errors::CREATE_CONSIGNMENT_PDF_FAILED || exception.error_code == TNTShipperLib::Errors::CONSIGNMENT_XML_FAILURE)
      self.data[:tnt_error] = exception.error_code
      self.data[:tnt_data] = exception.data
      self.save!
    end
  end

  def handle_awb_exceptions(exception)
    if (exception.class.to_s == BookingLib::Errors::AwbDocumentFailedException.to_s) && (exception.error_code == TNTShipperLib::Errors::CREATE_AWB_PDF_FAILED || exception.error_code == TNTShipperLib::Errors::AWB_XML_FAILURE)
      self.data[:tnt_error] = exception.error_code
      self.data[:tnt_data] = exception.data
      self.save!
    end
  end

  def handle_booking_failed_exception(exception)
    self.data[:tnt_error] = exception.error_code
    self.data[:tnt_api_errors] = exception.errors
    self.data[:tnt_data] = exception.data
    self.save!
  end

end

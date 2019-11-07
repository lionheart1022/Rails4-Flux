class UPSCarrierProductAutobookRequest < CarrierProductAutobookRequest
  # PUBLIC API
  class << self

  end

  # PUBLIC INSTANCE API

  # Returns the custom UPS background job queue name

  def autobook_shipment
    Rails.logger.debug "autobook started"
    # update state
    self.started

    # load data
    customer = Customer.find(self.customer_id)
    shipment = Shipment.find(self.shipment_id)

    # mark shipment as booking initiated
    shipment.booking_initiated(comment:'Booking with UPS', linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOKING_INITIATED, event_arguments: { shipment_id: shipment.id })

    # credentials
    carrier_product = shipment.carrier_product
    credentials     = UPSShipperLib::Credentials.new(access_token: carrier_product.get_credentials[:access_token], company: carrier_product.get_credentials[:company],
                                                     password: carrier_product.get_credentials[:password], account: carrier_product.get_credentials[:account])
    # convert data
    ups_sender, ups_recipient = [shipment.sender, shipment.recipient].map do |contact|

      # If no phone number is supplied, pass something to pass validation
      contact.phone_number.blank? ? phone_number = '0000000000' : phone_number = contact.phone_number

      new_contact = UPSShipperLib::Contact.new({
        company_name:           contact.company_name,
        attention:              contact.attention,
        email:                  contact.email,
        phone_number_number:    phone_number,
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

    ups_shipment = UPSShipperLib::Shipment.new({
      shipment_id:        shipment.unique_shipment_id,
      shipping_date:      shipment.shipping_date,
      number_of_packages: shipment.number_of_packages,
      package_dimensions: shipment.package_dimensions,
      customs_amount:     shipment.customs_amount,
      customs_currency:   shipment.customs_currency,
      customs_code:       shipment.customs_code,
      description:        shipment.description,
      dutiable:           shipment.dutiable,
      reference:          shipment.reference
    })

    ups_shipping_options = UPSShipperLib::ShippingOptions.new({
      service_code:   carrier_product.service,
      documents_only: carrier_product.ups_documents_only?,
      letter:         carrier_product.ups_letter?,
      import:         carrier_product.import?,
      packaging_code: carrier_product.packaging_code
      })

    if carrier_product.ups_return_service?
      ups_shipping_options.return_service_code = carrier_product.ups_return_service_code
    elsif carrier_product.import?
      ups_shipping_options.return_service_code = UPSShipperLib::ReturnServiceCodes::PRL
    else
      # From UPS docs: "QV Ship Notification is allowed for forward moving shipments only."
      ups_shipping_options.notification_code = UPSShipperLib::NotificationCodes::SHIP_NOTIFICATION
    end

    # perform booking with ups
    ups_shipper = UPSShipperLib.new
    booking     = ups_shipper.book_shipment(credentials: credentials, shipment: ups_shipment, sender: ups_sender, recipient: ups_recipient, shipping_options: ups_shipping_options)

    # pull out awb document and add to shipment
    shipment.create_or_update_awb_asset_from_local_file(file_path: booking.awb_file_path, linked_object: self)

    # pull out consignment note and add to shipment
    shipment.create_or_update_consignment_note_asset_from_local_file(file_path: booking.consignment_note_file_path, linked_object: self) if shipment.dutiable && !ups_shipping_options.import

    # delete any temp files
    ups_shipper.remove_temporary_files(booking: booking)

    # mark shipment as booked
    shipment.book(awb: booking.awb, comment: 'Booking completed', warnings: booking.warnings, linked_object: self)

    if booking.packages.length == shipment.package_dimensions.dimensions.length
      ActiveRecord::Base.transaction do
        shipment.update!(tracking_packages: true)

        booking.packages.each_with_index do |package_result, index|
          package = UPSPackage.create!(
            shipment: shipment,
            unique_identifier: package_result.tracking_number,
            package_index: index,
            metadata: {}
          )

          dimension = shipment.package_dimensions.dimensions[index]

          if dimension
            recording = package.recordings.create!(
              weight_value: dimension.weight,
              volume_weight_value: dimension.volume_weight,
              weight_unit: "kg",
              dimensions: {
                "length" => dimension.length,
                "width" => dimension.width,
                "height" => dimension.height,
                "unit" => "cm",
              }
            )

            package.update!(active_recording: recording)
          end
        end
      end
    else
      raise "The number of shipment packages (#{shipment.package_dimensions.dimensions.length}) and returned parcels do not match (#{booking.packages.length})"
    end

    # check for warnings
    event = shipment.shipment_warnings.empty? ? Shipment::Events::AUTOBOOK : Shipment::Events::AUTOBOOK_WITH_WARNINGS

    # email notification
    EventManager.handle_event(event: event, event_arguments: {shipment_id: shipment.id})

    if shipment.pickup_relation && shipment.pickup_relation.auto?
      pickup_request = UPSPickupHTTPRequest.build(credentials: credentials, pickup: shipment.pickup_relation, shipment: shipment)

      begin
        pickup_response = pickup_request.book_pickup!
      rescue UPSPickupHTTPRequest::UserValidationError => e
        shipment.pickup_relation.report_problem(comment: "Pickup could not be booked at UPS. Reason: #{e.message}")
      rescue => e
        shipment.pickup_relation.report_problem(comment: "Pickup could not be booked at UPS")

        ExceptionMonitoring.report!(e)
      else
        if pickup_response.success?
          shipment.pickup_relation.book(comment: "Pickup successfully booked at UPS (pickup request number: #{pickup_response.pickup_request_number})")
          shipment.pickup_relation.update!(carrier_identifier: "ups", response_from_carrier: { "prn" => pickup_response.pickup_request_number })
        elsif pickup_response.error?
          shipment.pickup_relation.report_problem(comment: pickup_response.error_message)
        end
      end
    end

    # completed
    self.completed

  rescue => exception
    self.handle_error(exception: exception)
  end

end

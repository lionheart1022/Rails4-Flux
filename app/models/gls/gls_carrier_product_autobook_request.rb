class GLSCarrierProductAutobookRequest < CarrierProductAutobookRequest
  def autobook_shipment
    started

    shipment.booking_initiated(comment: "Booking with GLS", linked_object: self)
    EventManager.handle_event(event: Shipment::Events::BOOKING_INITIATED, event_arguments: { shipment_id: shipment_id })

    carrier_product = shipment.carrier_product
    customer_carrier_product = CustomerCarrierProduct.find_customer_carrier_product(customer_id: customer_id, carrier_product_id: carrier_product.id)

    booking_request = GLSShipmentHTTPRequest.new(shipment)
    booking_request.test = customer_carrier_product.test

    if carrier_product.gls_deliver_to_parcelshop?
      booking_request.parcelshop_id = shipment.parcelshop_id.presence
      booking_request.parcelshop_id ||= begin
        search = GLSSearchNearestParcelshop.new(street: shipment.recipient.address_line1, zip_code: shipment.recipient.zip_code, country_code: shipment.recipient.country_code)
        parcelshop_result = search.get_result!
        parcelshop_result.number # Return the parcelshop ID
      rescue GLSSearchNearestParcelshop::UnknownAccuracyError => e
        return handle_gls_booking_error(message: "Could not find a parcelshop", error_code: "CF-GLS-PSACC")
      rescue GLSSearchNearestParcelshop::UnsuccessfulResponseError => e
        return handle_gls_booking_error(message: "Could not find a parcelshop: #{e.response.body}", error_code: "CF-GLS-PS#{e.response.code}")
      end
    end

    booking_response = nil

    begin
      booking_response = booking_request.book_shipment!
    rescue GLSShipmentHTTPResponse::ParameterError => e
      Rails.logger.tagged("GLS.Booking", "Request.Body") { Rails.logger.info booking_request.request_body }
      Rails.logger.tagged("GLS.Booking", "Response.Status") { Rails.logger.info e.response.code }
      Rails.logger.tagged("GLS.Booking", "Response.Body") { Rails.logger.info e.response.body }

      return handle_gls_booking_error(message: e.response_error_message, error_code: "CF-GLS-PARAM#{e.response_error_code ? "_#{e.response_error_code}" : ''}")
    rescue GLSShipmentHTTPResponse::UnknownError => e
      ExceptionMonitoring.report(e, context: {
        carrier_product_autobook_request_id: id,
        shipment_id: shipment_id,
        request_body: booking_request.request_body,
        response_code: e.response.code,
        response_body: e.response.body,
      })
      return handle_generic_exception(e)
    end

    booking_response.generate_temporary_awb_pdf_file do |awb_pdf_path|
      shipment.create_or_update_awb_asset_from_local_file(file_path: awb_pdf_path, linked_object: self)
    end

    shipment.book(awb: booking_response.awb_no, comment: "Booking completed", linked_object: self)

    gls_parcels = booking_response.parcels

    if gls_parcels.length == shipment.package_dimensions.dimensions.length
      ActiveRecord::Base.transaction do
        shipment.update!(tracking_packages: true)

        gls_parcels.each_with_index do |gls_parcel, index|
          package = GLSPackage.create!(
            shipment: shipment,
            unique_identifier: gls_parcel["ParcelNumber"],
            package_index: index,
            metadata: {
              "consignment_id" => booking_response.body["ConsignmentId"],
              "parcel_number" => gls_parcel["ParcelNumber"],
              "unique_number" => gls_parcel["UniqueNumber"],
            }
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
      raise "The number of shipment packages (#{shipment.package_dimensions.dimensions.length}) and returned parcels do not match (#{gls_parcels.length})"
    end

    EventManager.handle_event(event: Shipment::Events::AUTOBOOK, event_arguments: { shipment_id: shipment_id })

    shipment.update!(shipment_errors: nil) # Clear (possibly previous) errors
    completed
  rescue => exception
    ExceptionMonitoring.report(exception, context: {
      carrier_product_autobook_request_id: id,
      shipment_id: shipment_id,
    })
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

  def handle_gls_booking_error(message:, error_code: nil)
    shipment_errors = [Shipment::Errors::GenericError.new(code: error_code, description: message)]

    error(exception: nil, info: message)
    shipment.booking_fail(comment: message, errors: shipment_errors, linked_object: self)
    EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_PROBLEM, event_arguments: { shipment_id: shipment_id })

    if shipment.pickup_relation && shipment.pickup_relation.auto?
      shipment.pickup_relation.report_problem(comment: "The related shipment-booking failed")
    end
  end
end

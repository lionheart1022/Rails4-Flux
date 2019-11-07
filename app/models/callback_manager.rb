class CallbackManager

  class << self

    def handle_event(event: nil, event_arguments: nil)
      shipment_id  = event_arguments[:shipment_id]
      shipment     = Shipment.find(shipment_id)
      callback_url = shipment.latest_api_request.try(:callback_url)

      return if callback_url.blank?

      case event
        when Shipment::Events::AUTOBOOK
          handle_autobook_callback(shipment: shipment, callback_url: callback_url)
        when Shipment::Events::REPORT_AUTOBOOK_PROBLEM
          handle_booking_failed_callback(shipment: shipment, callback_url: callback_url)
      end
    end

    private

    def handle_autobook_callback(shipment: nil, callback_url: nil)
      awb                   = shipment.awb
      awb_asset_url         = shipment.asset_awb.try(:attachment).try(:url)
      consignment_asset_url = shipment.asset_consignment_note.try(:attachment).try(:url)
      invoice_asset_url     = shipment.asset_invoice.try(:attachment).try(:url)

      response = { status: shipment.state, unique_shipment_id: shipment.unique_shipment_id, awb: awb }
      response[:awb_asset_url]         = awb_asset_url if awb_asset_url.present?
      response[:consignment_asset_url] = consignment_asset_url if consignment_asset_url.present?
      response[:invoice_asset_url]     = invoice_asset_url if invoice_asset_url.present?

      response = response.to_json

      Faraday.post callback_url do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = response
      end

    rescue => e
      Rails.logger.error("\n\nautobook_callback_error\n #{e.inspect}")
    end

    def handle_booking_failed_callback(shipment: nil, callback_url: nil)
      errors = shipment.shipment_errors
      errors = errors.map do |error|
        {
          code: error.code,
          description: error.description
        }
      end

      response = { status: APIRequest::Statuses::FAILED, unique_shipment_id: shipment.unique_shipment_id, errors: errors }.to_json

      Faraday.post callback_url do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = response
      end

    rescue => e
      Rails.logger.error("\n\nautobook_callback_error\n #{e.inspect}")
    end

  end
end

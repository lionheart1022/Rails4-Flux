class FedExShipperLib < BookingLib
  module Errors
    BOOKING_FAILED = 'booking_failed'
    COULD_NOT_SCALE_LABEL = 'awb_failed__could_not_scale_label'
    COULD_NOT_TRIM_LABEL = 'awb_failed__could_not_trim_label'
  end

  module ServiceTypes
    INTERNATIONAL_ECONOMY = 'INTERNATIONAL_ECONOMY'
    INTERNATIONAL_PRIORITY = 'INTERNATIONAL_PRIORITY'
    INTERNATIONAL_PRIORITY_FREIGHT = 'INTERNATIONAL_PRIORITY_FREIGHT'
    PRIORITY_OVERNIGHT = 'PRIORITY_OVERNIGHT'
    STANDARD_OVERNIGHT = 'STANDARD_OVERNIGHT'
  end

  API_ENDPOINT = '/web-services'

  class Booking
    attr_reader :shipping_response, :warnings

    delegate :awb, :combined_awb_pdf, to: :shipping_response

    def initialize(shipping_response, warnings)
      @shipping_response = shipping_response
      @warnings          = warnings
    end
  end

  attr_reader :api_host

  def initialize(faraday_connection: nil, api_host: nil)
    @connection = faraday_connection
    @api_host = api_host
  end

  def book_shipment(args)
    shipment  = args.fetch(:shipment)
    sender    = args.fetch(:sender)
    recipient = args.fetch(:recipient)

    validation = validate(sender, recipient, shipment)

    if validation.invalid?
      raise BookingLib::Errors::BookingFailedException.new(
        error_code: Errors::BOOKING_FAILED,
        errors: validation.errors
      )
    end

    shipping_response = post_shipping_requst(shipment.id, args)

    if shipping_response.success?
      Booking.new(shipping_response, shipping_response.warnings_and_notes)
    else
      raise BookingLib::Errors::BookingFailedException.new(
        error_code: Errors::BOOKING_FAILED,
        errors: shipping_response.errors
      )
    end
  end

  private

  def post_shipping_requst(shipment_id, args)
    request = ShippingRequest.new(**args)

    response = connection.post do |req|
      req.url(API_ENDPOINT)
      req.body = request.as_string
    end

    ShippingResponse.new(response.body, shipment_id)
  end

  def validate(sender, recipient, shipment)
    Validation.new(
      sender: sender,
      recipient: recipient,
      shipment: shipment
    ).validate
  end

  def connection
    @connection ||= build_connection
  end

  def build_connection
    Faraday.new(:url => api_host) do |conn|
      conn.use FaradayMiddleware::FollowRedirects
      conn.request  :url_encoded
      conn.response :logger
      conn.adapter  Faraday.default_adapter
    end
  end
end

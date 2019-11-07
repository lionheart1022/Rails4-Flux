class Send24ShipperLib < BookingLib

  module Services
    PRIVATE  = "s24p"
    SAMEDAY  = "s24s"
  end

  module Response
    SUCCESSFUL = 'succes'
    AWB_NUMBER = 'order_number'
    AWB_URL    = 'link_to_pdf'

    # errors
    CODE = 'code'
    MESSAGE = 'message'
  end

  class Booking < BookingLib::Booking
    attr_reader :shipment_id

    def initialize(shipment_id: nil, awb: nil, awb_file_path: nil, consignment_note_file_path: nil, warnings: nil)
      @shipment_id = shipment_id

      super(awb: awb, awb_file_path: awb_file_path, consignment_note_file_path: consignment_note_file_path, warnings: warnings)
    end
  end

  class Credentials
    attr_reader :consumer_key, :consumer_secret

    def initialize(consumer_key: nil, consumer_secret: nil)
      @consumer_key   = consumer_key
      @consumer_secret = consumer_secret
    end
  end

  API_HOST     = 'https://send24.com'
  API_ENDPOINT = '/wc-api/v3/create_order'

  def initialize(credentials: nil, shipment: nil, sender: nil, recipient: nil, carrier_product: nil)
    @credentials     = credentials || Credentials.new
    @shipment        = shipment
    @sender          = sender
    @recipient       = recipient
    @carrier_product = carrier_product

    setup_connection
  end

  def book_shipment
    request_body = build_request_body

    response = send_request(request_body)
    data = JSON.parse(response.body)

    Rails.logger.debug request_body.inspect
    Rails.logger.debug data.inspect

    if data[Response::MESSAGE] != Response::SUCCESSFUL
      errors = parse_errors(data)
      raise BookingLib::Errors::BookingFailedException.new(error_code: BookingLib::Errors::BookingFailedException, errors: errors, data: data)
    end

    booking = extract_data_and_build_booking(data)
    booking
  rescue => e
    ExceptionMonitoring.report(e)

    Rails.logger.error("\nSend24ShipperLibError:\n#{e.human_friendly_text}\n")
    Rails.logger.error("\nSend24StackTrace:\n#{e.backtrace.join("\n")}\n")
    raise e
  end

  private

    def setup_connection
      @connection = Faraday.new(:url => API_HOST) do |conn|
        conn.use FaradayMiddleware::FollowRedirects
        conn.request  :url_encoded
        conn.response :logger
        conn.adapter  Faraday.default_adapter
      end

      @connection.basic_auth(@credentials.consumer_key, @credentials.consumer_secret)
    end

    def build_package_dimensions
      @shipment.package_dimensions.dimensions.map do |dim|
        {
          "width"  => dim.width,
          "height" => dim.height,
          "length" => dim.length,
          "weight" => dim.weight,
          "amount" => 1
        }
      end
    end

    def build_dutiable_data
      dutiable_data = {}

      dutiable_data["customs_amount"]   = @shipment.customs_amount   if @shipment.customs_amount
      dutiable_data["customs_currency"] = @shipment.customs_currency if @shipment.customs_currency
      dutiable_data["customs_code"]     = @shipment.customs_code     if @shipment.customs_code

      dutiable_data
    end

    def build_request_body
      weight       = @shipment.package_dimensions.total_weight
      product_code = @carrier_product.service
      names        = @recipient.attention.split(' ')
      firstname    = names.first
      lastname     = names.last == firstname ? nil : names.last
      address      = [@recipient.address_line1, @recipient.address_line2, @recipient.address_line3].join(' ')
      dimensions   = build_package_dimensions

      params = {
        "company"            => @recipient.company_name,
        "first_name"         => firstname,
        "last_name"          => lastname,
        "phone"              => @recipient.phone_number,
        "email"              => @recipient.email,
        "country_code"       => @recipient.country_code,
        "city"               => @recipient.city,
        "postcode"           => @recipient.zip_code,
        "address"            => address,
        "product_code"       => product_code,
        "description"        => @shipment.description,
        "reference"          => @shipment.reference,
        "package_dimensions" => dimensions
      }

      params["state_code"]       = @recipient.state_code      if @recipient.state_code
      params["shop_id"]          = @shipment.parcelshop_id    if @shipment.parcelshop_id
      params["dutiable"]         = @shipment.dutiable         if @shipment.dutiable
      params["dutiable_data"]    = build_dutiable_data        if @shipment.dutiable
      params["return_label"]     = @shipment.return_label     if @shipment.return_label

      Rails.logger.debug params

      params.to_json
    end

    def send_request(body)
      @connection.post do |req|
        req.url(API_ENDPOINT)
        req.body = body
        req.headers['Content-Type'] = 'application/json'
      end
    end

    # Parsing
    #
    #

    def extract_data_and_build_booking(data)
      awb = data[Response::AWB_NUMBER]
      url = data[Response::AWB_URL]
      file_path = download_file_from_url(url, @shipment)

      booking = Send24ShipperLib::Booking.new(shipment_id: @shipment.shipment_id, awb: awb, awb_file_path: file_path)
    end

    def parse_errors(data)
      message = data["message"]
      return [BookingLib::Errors::APIError.new(description: message)] if message # these are API errors


      data["errors"].map do |error| # these are errors HTTP-based errors
        code = error[Response::CODE]
        message = error[Response::MESSAGE]

        BookingLib::Errors::APIError.new(code: code, description: message)
      end
    end

    def download_file_from_url(url, shipment)
      conn = Faraday.new() do |conn|
        conn.use FaradayMiddleware::FollowRedirects
        conn.request  :url_encoded
        conn.response :logger
        conn.adapter  Faraday.default_adapter
      end

      response = conn.get(url)
      data     = response.body
      path     = "#{Rails.root}/tmp/#{shipment.unique_shipment_id}-awb_document.pdf"

      File.open(path, 'wb') do |f|
        f.write(data)
      end

      return path
    end

end

class GTXShipperLib < BookingLib

  class Booking < BookingLib::Booking
    attr_reader :shipment_id

    def initialize(shipment_id: nil, awb: nil, awb_file_path: nil, consignment_note_file_path: nil, warnings: nil)
      @shipment_id = shipment_id

      super(awb: awb, awb_file_path: awb_file_path, consignment_note_file_path: consignment_note_file_path, warnings: warnings)
    end
  end

  class Credentials
    attr_reader :username, :password

    def initialize(username: nil, password: nil)
      @username = username
      @password = password
    end
  end

  API_HOST     = 'http://gtx.nu'
  API_ENDPOINT = '/Services/Public/V3/Booking.asmx'

  module Response
    SUCCESS = 'true'
    FAILURE = 'false'

  end

  module Services
    GTX_ECONOMY_DHL_EXPORT                       = '15'
    GTX_EXPRESS_DHL_EXPORT                       = '22'
    GTX_EXPRESS_BEFORE_9_DHL_EXPORT              = '26'
    GTX_EXPRESS_BEFORE_12_DHL_EXPORT             = '27'

    GTX_BUSINESS_PDK                             = '66'
    GTX_PRIVATE_WITH_TRANSFER_PDK                = '67'
    # GTX_PRIVATE_WITHOUT_TRANSFER_DROPPOINT_PDK = '87'
    GTX_RETURN_PDK                               = '88'
  end

  def initialize(credentials: nil, shipment: nil, sender: nil, recipient: nil, carrier_product: nil)
    @credentials     = credentials || Credentials.new
    @shipment        = shipment
    @sender          = sender
    @recipient       = recipient
    @carrier_product = carrier_product

    setup_connection
  end

  def book_shipment(credentials: nil, shipment: nil, sender: nil, recipient: nil, test: nil)
    errors = validate_request
    raise BookingLib::Errors::BookingFailedException.new(error_code: BookingLib::Errors::BookingFailedException, errors: errors) if errors.present?

    request_body  = build_request_body
    response_body = send_request(request_body).body

    if failure?(response_body)
      errors = parse_errors(response_body)
      errors = [system_error] if errors.empty?

      raise BookingLib::Errors::BookingFailedException.new(error_code: BookingLib::Errors::BookingFailedException, errors: errors)
    end

    booking = extract_data_and_build_booking(response_body)
    booking
  rescue => e
    ExceptionMonitoring.report(e)

    Rails.logger.error("\nGTXShipperLibError:\n#{e.inspect}\n")
    Rails.logger.error("\nGTXStackTrace:\n#{e.backtrace.join("\n")}\n")
    raise e
  end

  private

    # HTTP
    #
    #

    def setup_connection
      @connection = Faraday.new(:url => API_HOST) do |conn|
        conn.use FaradayMiddleware::FollowRedirects
        conn.request  :url_encoded
        conn.response :logger
        conn.adapter  Faraday.default_adapter
      end
    end

    def build_request_body
      credentials     = @credentials
      shipment        = @shipment
      sender          = @sender
      recipient       = @recipient
      carrier_product = @carrier_product

      template = ERB.new(File.read(path_to_template(filename: 'gtx_shipper_template.xml.erb')))
      template.result(binding)
    end

    def validate_request
      is_domestic    = @sender.country_code.downcase == @recipient.country_code.downcase
      is_dhl_economy = @carrier_product.service == Services::GTX_ECONOMY_DHL_EXPORT

      errors = []
      errors << BookingLib::Errors::APIError.new(code: 'GTX-1', description: 'DHL Economy only available for international shipments') if is_domestic && is_dhl_economy

      errors
    end

    def format_dimension(dim)
      dim * 10
    end

    def format_weight(weight)
      weight * 1000
    end

    def format_country(code)
      code.upcase
    end

    def send_request(body)
      @connection.post do |req|
        req.url(API_ENDPOINT)
        req.body = body
        req.headers['Content-Type'] = 'application/soap+xml; charset=utf-8'
      end
    end

    # Response Parsing
    #
    #

    def failure?(response_body)
      doc   = Nokogiri::XML(response_body).remove_namespaces!
      error = doc.xpath('//BookingResult/Success').try(:text)

      error != Response::SUCCESS
    end

    def system_error
      BookingLib::Errors::APIError.new(code: 'GTX-0', description: 'system error')
    end

    def parse_errors(response_body)
      doc   = Nokogiri::XML(response_body).remove_namespaces!
      doc.xpath('//BookingResult/StatusList/V3dStatus').map do |node|
        Rails.logger.debug "adsad"
        code        = node.xpath('./Code').try(:text)
        description = node.xpath('./Text').try(:text)
        severity    = node.xpath('./Severity').try(:text)

        Rails.logger.debug code
        Rails.logger.debug description
        Rails.logger.debug severity

        BookingLib::Errors::APIError.new(code: code, description: description)
      end
    end

    def extract_data_and_build_booking(response_body)
      doc                = Nokogiri::XML(response_body).remove_namespaces!
      awb                = doc.xpath('//BookingResult/WayBillNumberHead').try(:text)
      base64_encoded_pdf = doc.xpath('//V3dBinaryImage').first.xpath('./ImageBase64').try(:text)
      pdf                = Base64.decode64(base64_encoded_pdf)

      path = "#{Rails.root}/tmp/#{@shipment.unique_shipment_id}-awb_document.pdf"
      save_pdf_and_create_temp_file(pdf, path)

      GTXShipperLib::Booking.new(shipment_id: @shipment.shipment_id, awb: awb, awb_file_path: path)
    end

    def save_pdf_and_create_temp_file(data, path)
      pdf_file = File.open(path, 'wb') do |f|
        f.write(data)
      end
    end

end

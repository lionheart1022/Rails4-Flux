class DHLShipperLib < BookingLib

  class Booking < BookingLib::Booking
    attr_reader :shipment_id

    def initialize(shipment_id: nil, awb: nil, awb_file_path: nil, consignment_note_file_path: nil, warnings: nil)
      @shipment_id = shipment_id

      super(awb: awb, awb_file_path: awb_file_path, consignment_note_file_path: consignment_note_file_path, warnings: warnings)
    end
  end

  class Credentials
    attr_reader :company, :password, :account

    def initialize(company: nil, password: nil, account: nil)
      @account         = account
      @company         = company
      @password        = password
    end
  end

  API_TEST_HOST        = 'https://xmlpitest-ea.dhl.com/'
  API_PROD_HOST        = 'https://xmlpi-ea.dhl.com/'
  API_BOOKING_ENDPOINT = '/XMLShippingServlet'

  module Errors
    INVALID_ARGUMENT              = 'invalid_argument'
    CREATE_BOOKING_FAILED         = 'create_booking_failed'
    SHIP_BOOKING_FAILED           = 'ship_booking_failed'
    UNKNOWN_ERROR                 = 'unknown_error'
    FILE_ERROR                    = 'file_error'
  end

  module Codes
    module Services
      EXPRESS_DUTIABLE    = 'P'
      EXPRESS_NONDUTIABLE = 'U'
      EXPRESS_BEFORE_9_DUTIABLE = 'E'
      EXPRESS_BEFORE_9_NONDUTIABLE = 'K'
      EXPRESS_BEFORE_12_DUTIABLE = 'Y'
      EXPRESS_BEFORE_12_NONDUTIABLE = 'T'

      ECONOMY_DUTIABLE    = 'H'
      ECONOMY_NONDUTIABLE = 'W'

      EXPRESS_ENVELOPE = 'X'
      EXPRESS_DOCUMENT = 'D'
      ECONOMY_DOCUMENT = 'D'

      EXPRESS_DOMESTIC = 'N'
      ECONOMY_DOMESTIC = 'G' # no longer available
    end

    module PackageTypes
      CUSTOMER_PROVIDED = 'CP'
      EXPRESS_DOCUMENT  = 'ED'
    end

    module DeliveryType
      DOOR_TO_DOOR = 'DD'
    end

    module PaymentType
      SENDER    = 'S'
      RECIPIENT = 'R'
    end

    module Dutiable
      YES = 'Y'
      NO  = 'N'
    end

    module Metrics
      KILOGRAMS   = 'K'
      CENTIMETERS = 'C'
    end
  end

  def initialize
    host = Rails.env.production? ? API_PROD_HOST : API_TEST_HOST

    @connection = Faraday.new(:url => host) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  def book_shipment(credentials: nil, shipment: nil, sender: nil, recipient: nil, carrier_product: nil, dgr_mapping: nil)
    run_validations(shipment, carrier_product)

    request_body = prepare_request(binding)
    Rails.logger.debug "\nDHLRequestBody\n#{request_body}\n"

    response = @connection.post do |req|
      req.url(API_BOOKING_ENDPOINT)
      req.body = request_body
    end

    response_body = response.body
    if errors?(response_body)
      errors  = parse_errors(response_body)
      context = error_context(request_body, response_body)

      raise BookingLib::Errors::BookingFailedException.new(error_code: DHLShipperLib::Errors::SHIP_BOOKING_FAILED, errors: errors, data: context)
    end
    Rails.logger.debug "\nDHLResponseBody\n#{response_body}\n"

    booking = extract_data_and_build_booking(response_body, shipment)

    return booking
  rescue => e
    ExceptionMonitoring.report(e)

    Rails.logger.error("\nDHLShipperLibError:\n#{e.inspect}\n")
    raise e
  end

  def payment_type(import)
    import ? Codes::PaymentType::RECIPIENT : Codes::PaymentType::SENDER
  end

  def is_dutiable(dutiable)
    dutiable ? Codes::Dutiable::YES : Codes::Dutiable::NO
  end

  def format_country_code(code)
    code.upcase
  end

  def country_name(code)
    Country.new(code).name.truncate(35)
  end

  def format_date(date)
    date.strftime('%Y-%m-%d')
  end

  def format_customs_amount(amount)
    return '' if amount.blank?
    '%0.2f' % amount
  end

  def format_customs_currency(string)
    string.present? ? string : 'DKK'
  end

  def format_region_code(contact)
    case contact.region
    when Contact::Regions::EUROPE
      "EU"
    when Contact::Regions::AMERICAS
      "AM"
    when Contact::Regions::ASIA
      "AP"
    end
  end

  def remove_temporary_files(booking)
    File.delete(booking.awb_file_path) unless booking.awb_file_path.nil?
    File.delete(booking.consignment_note_file_path) unless booking.consignment_note_file_path.nil?
  rescue => exception
    ExceptionMonitoring.report(exception)
    raise BookingLib::Errors::RemoveTemporaryFilesFailedException.new(error_code: DHLShipperLib::Errors::FILE_ERROR)
  end

  private

    def run_validations(shipment, carrier_product)
      validation_errors = []
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-DHL-001", description: "Dutiable shipment required for selected service") if !shipment.dutiable && carrier_product.dutiable_required?

      raise BookingLib::Errors::BookingFailedException.new(error_code: DHLShipperLib::Errors::INVALID_ARGUMENT, errors: validation_errors) if validation_errors.present?
    end

    def error_context(request, response)
      "Response:\n#{response}\n\nRequest:\n#{request}"
    end

    def extract_awb_number(doc)
      pdf = doc.xpath('//AirwayBillNumber/text()').try(:text)
    end

    def extract_awb_document(doc)
      pdf = doc.xpath('//LabelImage/OutputImage/text()').try(:text)
    end

    def extract_data_and_build_booking(response_body, shipment)
      doc  = Nokogiri::XML(response_body)

      awb                = extract_awb_number(doc)
      base64_encoded_pdf = extract_awb_document(doc)
      pdf                = Base64.decode64(base64_encoded_pdf)
      path               = "#{Rails.root}/tmp/#{shipment.unique_shipment_id}-awb_document.pdf"
      save_pdf_and_create_temp_file(pdf, path)

      booking = DHLShipperLib::Booking.new(awb: awb, awb_file_path: path)
    end

    def save_pdf_and_create_temp_file(data, path)
      pdf_file = File.open(path, 'wb') do |f|
        f.write(data)
      end
    end

    # Populates xml template with shipment data
    #
    def prepare_request(binding)
      template = ERB.new(File.read(path_to_template(filename: 'dhl_shipper_template.xml.erb')))
      template.result(binding)
    end

    def errors?(response_body)
      doc    = Nokogiri::XML(response_body)
      status = doc.xpath('//Status/ActionStatus/text()').try(:text)
      code   = doc.xpath('//Status/Condition/ConditionCode/text()').try(:text)
      status == 'Error' || code.present?
    end

    def parse_errors(response_body)
      doc    = Nokogiri::XML(response_body)
      errors = doc.xpath('//Status/Condition').map do |node|
        code        = node.xpath('./ConditionCode').try(:text)
        description = node.xpath('./ConditionData').try(:text)

        BookingLib::Errors::APIError.new(code: code, description: description)
      end

      return errors
    end

end

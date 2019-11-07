require 'base64'
require 'rexml/document'

class UPSShipperLib < BookingLib
  attr_reader :digest

  module ServiceCodes
    module International
      STANDARD = '11'
      EXPRESS = '07'
      EXPEDITED = '08'
      SAVER = '65'
    end

    module Domestic
      EXPRESS = '07'
    end
  end

  module PackagingCodes
    CUSTOMER_SUPPLIED_PACKAGE = '02'
    DOCUMENT                  = '01'
    LETTER                    = '01'
  end

  module ReturnServiceCodes
    RS_1_ATTEMPT = "3"
    RS_3_ATTEMPT = "5"
    PRL = "9"
  end

  module NotificationCodes
    SHIP_NOTIFICATION = "6" # QV Ship Notification
  end

  module Errors
    INVALID_ARGUMENT              = 'invalid_argument'
    DIGEST_NOT_FOUND              = 'digest_not_found'
    CREATE_BOOKING_FAILED         = 'create_booking_failed'
    SHIP_BOOKING_FAILED           = 'ship_booking_failed'
    UNKNOWN_ERROR                 = 'unknown_error'
  end

  class Booking < BookingLib::Booking
    attr_reader :shipment_id
    attr_reader :packages

    def initialize(shipment_id: nil, packages: nil, awb: nil, awb_file_path: nil, consignment_note_file_path: nil, warnings: nil)
      @shipment_id = shipment_id
      @packages = Array(packages)

      super(awb: awb, awb_file_path: awb_file_path, consignment_note_file_path: consignment_note_file_path, warnings: warnings)
    end
  end

  class PackageResult
    attr_reader :node

    class << self
      def build_from_node(node)
        new(node)
      end
    end

    def initialize(node)
      @node = node
    end

    def tracking_number
      @_tracking_number ||= node.at_xpath("./TrackingNumber").text
    end
  end

  class Credentials
    attr_reader :access_token, :company, :password, :account

    def initialize(access_token: nil, company: nil, password: nil, account: nil)
      @access_token    = access_token
      @account         = account
      @company         = company
      @password        = password
    end
  end

  class Contact
    attr_reader :company_name, :attention, :email, :phone_number_dial_code, :phone_number_number, :address_line1, :address_line2, :address_line3, :zip_code, :city, :country_code, :state_code

    def initialize(company_name: nil, attention: nil, email: nil, phone_number_dial_code: nil, phone_number_number: nil, address_line1: nil, address_line2: nil, address_line3: nil, zip_code: nil, city: nil, country_code: nil, state_code: nil)
      @company_name           = company_name
      @attention              = attention
      @email                  = email
      @phone_number_dial_code = phone_number_dial_code
      @phone_number_number    = phone_number_number
      @address_line1          = address_line1
      @address_line2          = address_line2
      @address_line3          = address_line3
      @zip_code               = zip_code
      @city                   = city
      @country_code           = country_code
      @state_code             = state_code
    end
  end

  class ShippingOptions
    attr_reader :service_code, :documents_only, :letter, :import, :packaging_code
    attr_accessor :return_service_code
    attr_accessor :notification_code

    def initialize(service_code: nil, documents_only: false, letter: false, packaging_code: nil, import: nil)
      @service_code   = service_code
      @documents_only = documents_only
      @letter         = letter
      @import         = import
      @packaging_code = packaging_code
    end
  end

  class Shipment
    attr_reader :request_options, :reference_code, :service_code, :customs_amount, :number_of_packages, :packaging_code, :customs_code, :reference,
                :package_dimensions, :customs_currency, :description, :shipment_id, :shipping_date, :dutiable

    def initialize(request_options: nil, reference_code: nil, service_code: nil, customs_amount: nil, number_of_packages: nil, packaging_code: nil, customs_code: nil, reference: nil,
                   package_dimensions: nil, customs_currency: nil, description: nil, shipment_id: nil, shipping_date: nil, dutiable: nil)
      @shipment_id                       = shipment_id
      @shipping_date                     = shipping_date
      @customs_currency                  = customs_currency
      @customs_amount                    = customs_amount
      @customs_code                      = customs_code
      @number_of_packages                = number_of_packages
      @description                       = description
      @package_dimensions                = package_dimensions
      @dutiable                          = dutiable
      @reference                         = reference
    end
  end

  # production : staging
  API_HOST = Rails.env.production? ? 'https://onlinetools.ups.com' : 'https://wwwcie.ups.com'

  API_CONFIRM_ENDPOINT   = '/ups.app/xml/ShipConfirm'
  API_ACCEPT_ENDPOINT    = '/ups.app/xml/ShipAccept'

  def initialize
    @connection = Faraday.new(:url => API_HOST) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  def book_shipment(credentials: nil, shipment: nil, sender: nil, recipient: nil, shipping_options: nil)
    # validate argument types
    arg_errors = []
    arg_errors << [credentials, UPSShipperLib::Credentials] unless credentials.is_a?(UPSShipperLib::Credentials)
    arg_errors << [shipment, UPSShipperLib::Shipment] unless shipment.is_a?(UPSShipperLib::Shipment)
    arg_errors << [sender, UPSShipperLib::Contact] unless sender.is_a?(UPSShipperLib::Contact)
    arg_errors << [recipient, UPSShipperLib::Contact] unless recipient.is_a?(UPSShipperLib::Contact)

    # raise error
    unless arg_errors.empty?
      arg_errors_strings = arg_errors.map {|e| "#{e[0].class.to_s} should have been a #{e[1]}" }
      raise BookingLib::Errors::BookingLibException.new(error_code: UPSShipperLib::Errors::INVALID_ARGUMENT, errors: arg_errors_strings)
    end

    # validate argument data
    validation_errors = []

    # Sender + recipient
    [sender, recipient].each_with_index do |contact, idx|
      contact_name = ["Sender", "Recipient"][idx]
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-#{idx+1}00", description: "#{contact_name} company name is mandatory") if contact.company_name.blank?
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-#{idx+1}01", description: "#{contact_name} attention name is mandatory") if contact.attention.blank?
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-#{idx+1}02", description: "#{contact_name} address line 1 is mandatory") if contact.address_line1.blank?
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-#{idx+1}03", description: "#{contact_name} zip code is mandatory") if contact.zip_code.blank?
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-#{idx+1}04", description: "#{contact_name} city is mandatory") if contact.city.blank?
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-#{idx+1}05", description: "#{contact_name} country is mandatory") if contact.country_code.blank?

      validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-#{idx+1}06", description: "#{contact_name} company name cannot be longer than 35 characters") if contact.company_name.length > 35
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-#{idx+1}07", description: "#{contact_name} address line 1 cannot be longer than 35 characters") if contact.address_line1.length > 35
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-#{idx+1}08", description: "#{contact_name} address line 2 cannot be longer than 35 characters") if contact.address_line2 && contact.address_line2.length > 35
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-#{idx+1}09", description: "#{contact_name} city cannot be longer than 30 characters") if contact.city.length > 30
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-#{idx+1}10", description: "#{contact_name} zip code cannot be longer than 9 characters") if contact.zip_code.length > 9
    end

    # shipment
    validation_errors << BookingLib::Errors::APIError.new(code:"CF-UPS-011", description: "Reference field cannot be longer than 35 characters") if shipment.reference && shipment.reference.length > 35

    # raise error if validation errors
    unless validation_errors.empty?
      raise BookingLib::Errors::BookingFailedException.new(error_code: UPSShipperLib::Errors::INVALID_ARGUMENT, errors: validation_errors)
    end

    # load confirm request template
    shipment_confirm_request_xml_template = ERB.new(File.read(path_to_template(filename: 'ups_confirm_request_template.xml.erb')))

    # populate template
    shipment_confirm_request_xml = shipment_confirm_request_xml_template.result(binding)

    Rails.logger.debug "Request: \n" + shipment_confirm_request_xml

    # confirm request
    confirm_response = @connection.post do |req|
      req.url(API_CONFIRM_ENDPOINT)
      req.body = shipment_confirm_request_xml
    end

    # parse response
    confirm_response_body = confirm_response.body

    Rails.logger.debug "Response: \n" + confirm_response_body
    doc = Nokogiri::XML(confirm_response_body)

    # raise error if first request failed
    errors = self.parse_errors_from_response(response: confirm_response_body)

    Rails.logger.debug "Errors: \n #{errors}"
    Rails.logger.debug "HardErrors: #{filter_hard_errors(errors: errors)}"
    if filter_hard_errors(errors: errors).size > 0
      raise BookingLib::Errors::BookingFailedException.new(error_code: UPSShipperLib::Errors::SHIP_BOOKING_FAILED, errors: errors, data: confirm_response_body)
    end

    # extract shipping digest
    @digest = doc.xpath('ShipmentConfirmResponse/ShipmentDigest')[0].content.to_s
    raise BookingLib::Errors::BookingFailedException.new(error_code: UPSShipperLib::Errors::DIGEST_NOT_FOUND, data: confirm_response_body) unless @digest

    # load accept request template
    shipment_accept_request_xml_template = ERB.new(File.read(path_to_template(filename: 'ups_accept_request_template.xml.erb')))

    # populate template
    shipment_accept_request_xml = shipment_accept_request_xml_template.result(binding)

    # accept request
    accept_response = @connection.post do |req|
      req.url(API_ACCEPT_ENDPOINT)
      req.body = shipment_accept_request_xml
    end

    # parse response
    accept_response_body = accept_response.body
    doc = Nokogiri::XML(accept_response_body)

    # raise error if second request failed
    errors += self.parse_errors_from_response(response: accept_response_body)
    if filter_hard_errors(errors: errors).size > 0
      raise BookingLib::Errors::BookingFailedException.new(error_code: UPSShipperLib::Errors::SHIP_BOOKING_FAILED, errors: errors, data: accept_response_body)
    end

    consignment_note_file_path = nil
    if shipment.dutiable && !shipping_options.import
      # extract invoice
      base64_encoded_image = doc.xpath('/ShipmentAcceptResponse/ShipmentResults/Form/Image/GraphicImage')[0].content.to_s
      image_path = "#{Rails.root}/tmp/consignment_note.pdf"
      image_file = File.open(image_path, 'wb') do |f|
        f.write(Base64.decode64(base64_encoded_image))
      end

      consignment_note_file_path = image_path
    end

    base64_encoded_gif_labels = doc.xpath("/ShipmentAcceptResponse/ShipmentResults/PackageResults/LabelImage/GraphicImage/text()").map(&:to_s)

    # extract awb (track and trace number)
    tracking_number = doc.xpath('/ShipmentAcceptResponse/ShipmentResults/PackageResults/TrackingNumber')[0].content.to_s

    packages = doc.xpath('/ShipmentAcceptResponse/ShipmentResults/PackageResults').map do |node|
      PackageResult.build_from_node(node)
    end

    # Consolidate labels into a single file
    label_pdf_file_path = Rails.root.join("tmp", "shipping_label.pdf")
    label_consolidation = UPSLabelConsolidation.new(base64_encoded_gif_labels)
    label_consolidation.perform!
    label_consolidation.write!(label_pdf_file_path)

    # filter warnings from errors
    warnings = filter_warnings(errors: errors)

    # create response
    booking = UPSShipperLib::Booking.new(packages: packages, awb: tracking_number, awb_file_path: label_pdf_file_path, consignment_note_file_path: consignment_note_file_path, warnings: warnings)

  rescue => exception
    ExceptionMonitoring.report(exception)
    Rails.logger.error "UPSShipperLibError #{exception}"

    if exception.is_a?(BookingLib::Errors::BookingFailedException)
      raise exception
    else
      raise BookingLib::Errors::BookingFailedException.new(error_code: UPSShipperLib::Errors::UNKNOWN_ERROR, errors: ["Exception message: #{exception.try(:message)}"], data: "Exception backtrace: #{exception.try(:backtrace).try(:inspect)}")
    end
  end

  def remove_temporary_files(booking: nil)
    File.delete(booking.awb_file_path) unless booking.awb_file_path.nil?
    File.delete(booking.consignment_note_file_path) unless booking.consignment_note_file_path.nil?
  rescue => exception
    ExceptionMonitoring.report(exception)
    raise BookingLib::Errors::RemoveTemporaryFilesFailedException.new(error_code: UPSShipperLib::Errors::UNKNOWN_ERROR)
  end

  def parse_errors_from_response(response: nil)
    doc = Nokogiri::XML(response)

    errors = doc.xpath('ShipmentConfirmResponse/Response/Error').map do |error|
      code        = error.xpath('./ErrorCode')[0].content.to_s
      severity    = error.xpath('./ErrorSeverity')[0].content.to_s
      description = error.xpath('./ErrorDescription')[0].content.to_s

      BookingLib::Errors::APIError.new(code: code, description: description, severity: severity)
    end

    return errors
  end

  def filter_warnings(errors: nil)
    errors.select{ |error| error.severity == "Warning"}
  end

  def filter_hard_errors(errors: nil)
    errors.select{ |error| error.severity == "Hard"}
  end

  def transform_to_ups_char_set(string)
    transliterated_string = I18n.transliterate(string.to_s)
    escaped_string        = xml_escape(transliterated_string)

    escaped_string
  end

  def xml_escape(string)
    REXML::Text.new(string, false, nil, false).to_s
  end

end

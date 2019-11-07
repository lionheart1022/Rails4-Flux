# Perform bookings with TNT
#
# Can book consignments with TNT through their API
# Requires an existing agreement with TNT
#
# Limitations:
# Can only book one consignment at a time. Each consignment can consist of several packages.

require 'rexml/document'

class TNTShipperLib < BookingLib

  module ServiceCodes
    module Domestic
      EXPRESS = '15'
    end

    module International
      EXPRESS           = '15N'
      EXPRESS_DOCUMENT  = '15D'
      ECONOMY_EXPRESS   = '48N'
    end
  end

  module Errors
    INVALID_ARGUMENT              = 'invalid_argument'
    ACCESS_ID_NOT_FOUND           = 'access_id_not_found'
    CREATE_BOOKING_FAILED         = 'create_booking_failed'
    SHIP_BOOKING_FAILED           = 'ship_booking_failed'
    AWB_XML_FAILURE               = 'awb_xml_failure'
    CONSIGNMENT_XML_FAILURE       = 'consignment_xml_failure'
    CREATE_AWB_PDF_FAILED         = 'create_awb_pdf_failed'
    CREATE_CONSIGNMENT_PDF_FAILED = 'create_consignment_note_pdf_failed'
    CONNECTION_FAILED             = 'connection_failed'
    RUNTIME_ERROR                 = 'runtime_error'
    UNKNOWN_ERROR                 = 'unknown_error'
    FILE_ERROR                    = 'file_error'
    PDF_TRANSFORM_ERROR           = 'pdf_transform_error'
  end

  PDF_GEN_TIMEOUT_THRESHOLD = 10

  class Credentials
    attr_reader :company, :password, :account

    def initialize(company: nil, password: nil, account: nil)
      @company  = company
      @password = password
      @account  = account
    end
  end

  class ShippingOptions
    attr_reader :service, :import

    def initialize(service: nil, import: nil)
      @service = service
      @import  = import
    end

    def contype
      case @service
        when TNTShipperLib::ServiceCodes::International::EXPRESS_DOCUMENT
          "D"
        else
          "N"
      end
    end
  end

  class Booking < BookingLib::Booking
    attr_reader :access_id, :shipment_id, :consignment_reference, :consignment_number, :booking_reference

    def initialize(access_id: nil, shipment_id: nil, consignment_reference: nil, consignment_number: nil, awb_file_path: nil, consignment_note_file_path: nil, booking_reference: nil)
      @access_id              = access_id
      @shipment_id            = shipment_id
      @consignment_reference  = consignment_reference
      @consignment_number     = consignment_number
      @booking_reference      = booking_reference

      super(awb: consignment_number, awb_file_path: awb_file_path, consignment_note_file_path: consignment_note_file_path)
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

  class Shipment
    attr_reader :shipment_id, :shipping_date, :number_of_packages, :package_dimensions, :dutiable, :customs_amount, :customs_currency, :customs_code, :description, :reference, :minimized_reference

    def initialize(shipment_id: nil, shipping_date: nil, number_of_packages: nil, package_dimensions: nil, dutiable: nil, customs_amount: nil, customs_currency: nil, customs_code: nil, description: nil, reference: nil, minimized_reference: nil)

      @shipment_id         = shipment_id
      @shipping_date       = shipping_date
      @number_of_packages  = number_of_packages
      @package_dimensions  = package_dimensions
      @dutiable            = dutiable
      @customs_amount      = customs_amount
      @customs_currency    = customs_currency
      @customs_code        = customs_code
      @description         = description
      @reference           = reference
      @minimized_reference = minimized_reference
    end
  end

  class CollectionInfo
    attr_accessor :company_name
    attr_accessor :attention
    attr_accessor :email
    attr_accessor :dial_code
    attr_accessor :telephone
    attr_accessor :address_line1
    attr_accessor :address_line2
    attr_accessor :address_line3
    attr_accessor :zip_code
    attr_accessor :city
    attr_accessor :country_code
    attr_accessor :state_code
    attr_accessor :from_time, :to_time
    attr_accessor :instructions
    attr_accessor :book

    def self.new_from_contact(contact)
      new(
        company_name: contact.company_name,
        attention: contact.attention,
        email: contact.email,
        phone_number: contact.phone_number,
        address_line1: contact.address_line1,
        address_line2: contact.address_line2,
        address_line3: contact.address_line3,
        zip_code: contact.zip_code,
        city: contact.city,
        country_code: contact.country_code,
        state_code: contact.state_code,
      )
    end

    def initialize(params = {})
      self.book = false
      self.from_time = "09:00"
      self.to_time = "10:00"
      # The collection times have to be there, but are not used as long as we only ship, not book, the consignments
      self.instructions = ""

      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end if params
    end

    def phone_number=(phone_number)
      if phone_number.present?
        phone_number_filtered = phone_number.scan(/[^\-\+\(\) \/]+/).join("")
        phone_number_truncated = phone_number_filtered.truncate(16, omission: '')
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

      self.dial_code = phone_number_dial_code
      self.telephone = phone_number_number
    end

    def book?
      book.present?
    end
  end

  API_HOST      = 'https://express.tnt.com'
  API_ENDPOINT  = '/expressconnect/shipping/ship'

  def initialize
    @connection = Faraday.new(:url => API_HOST, timeout: 60, open_timeout: 60) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  # @param [TNTShipperLib::Shipment] shipment
  # @param [TNTShipperLib::Contact] recipient
  # @param [TNTShipperLib::Contact] sender
  # @param [TNTShipperLib::ShippingOptions] shipping_options
  #
  # @return [TNTShipperLib::Booking]
  def book_shipment(credentials: nil, shipment: nil, sender: nil, recipient: nil, collection_info: nil, shipping_options: nil)
    # validate argument types
    arg_errors = []
    arg_errors << [credentials, TNTShipperLib::Credentials] unless credentials.is_a?(TNTShipperLib::Credentials)
    arg_errors << [shipment, TNTShipperLib::Shipment] unless shipment.is_a?(TNTShipperLib::Shipment)
    arg_errors << [sender, TNTShipperLib::Contact] unless sender.is_a?(TNTShipperLib::Contact)
    arg_errors << [recipient, TNTShipperLib::Contact] unless recipient.is_a?(TNTShipperLib::Contact)
    arg_errors << [collection_info, TNTShipperLib::CollectionInfo] unless collection_info.is_a?(TNTShipperLib::CollectionInfo)
    arg_errors << [shipping_options, TNTShipperLib::ShippingOptions] unless shipping_options.is_a?(TNTShipperLib::ShippingOptions)

    # raise error

    unless arg_errors.empty?
      arg_errors_strings = arg_errors.map {|e| "#{e[0].class.to_s} should have been a #{e[1]}" }
      raise BookingLib::Errors::BookingLibException.new(error_code: TNTShipperLib::Errors::INVALID_ARGUMENT, errors: arg_errors_strings)
    end

    # validate argument data
    validation_errors = []
    validation_errors << BookingLib::Errors::APIError.new(code:'CF-TNT-1', description:" Description cannot be longer than 90 characters") if shipment.description.length > 90
    validation_errors << BookingLib::Errors::APIError.new(code:'CF-TNT-2', description:" Reference cannot exceed 18 characters") if shipment.reference.length > 18

    # Sender + recipient
    [sender, recipient].each_with_index do |contact, idx|
      contact_name = ["Sender", "Recipient"][idx]
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-TNT-#{idx+1}00", description: "#{contact_name} company name cannot be longer than 50 characters") if contact.company_name.length > 50
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-TNT-#{idx+1}01", description: "#{contact_name} address line 1 cannot be longer than 30 characters") if contact.address_line1.length > 30
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-TNT-#{idx+1}02", description: "#{contact_name} address line 2 cannot be longer than 30 characters") if contact.address_line2.length > 30
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-TNT-#{idx+1}03", description: "#{contact_name} city cannot be longer than 30 characters") if contact.city.length > 30
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-TNT-#{idx+1}04", description: "#{contact_name} zip code cannot be longer than 9 characters") if contact.zip_code.length > 9
    end

    # raise error

    unless validation_errors.empty?
      raise BookingLib::Errors::BookingFailedException.new(error_code: TNTShipperLib::Errors::INVALID_ARGUMENT, errors: validation_errors)
    end

    # load request template
    shipment_request_xml_template = ERB.new(File.read(path_to_template(filename: 'tnt_shipper_template.xml.erb')))

    # populate template
    shipment_request_xml = shipment_request_xml_template.result(binding)

    # book shipment
    begin
      book_response = @connection.post do |req|
        req.url(API_ENDPOINT)
        req.body = 'xml_in=' + CGI::escape(shipment_request_xml)
      end
    rescue
      errors = [BookingLib::Errors::APIError.new(code:"CF-TNT-NET", description: 'A connection problem occured')]
      raise BookingLib::Errors::BookingFailedException.new(error_code: TNTShipperLib::Errors::CONNECTION_FAILED, errors: errors)
    end

    # get access id
    book_response_body = book_response.body
    access_id_match = book_response_body.match(/COMPLETE:(.*)/)
    access_id = access_id_match ? access_id_match[1] : nil
    raise BookingLib::Errors::BookingFailedException.new(error_code: TNTShipperLib::Errors::ACCESS_ID_NOT_FOUND, data: book_response_body) unless access_id

    # get booking result
    begin
      result_response = @connection.post do |req|
        req.url(API_ENDPOINT)
        req.body = 'xml_in=' + 'GET_RESULT:' + access_id
      end
    rescue
      errors = [BookingLib::Errors::APIError.new(code:"CF-TNT-NET", description: 'A connection problem occured')]
      raise BookingLib::Errors::BookingFailedException.new(error_code: TNTShipperLib::Errors::CONNECTION_FAILED, errors: errors)
    end

    # extract data from result
    result_response_body = result_response.body
    doc = Nokogiri::XML(result_response_body)
    create_success = doc.xpath('/document/CREATE/SUCCESS/text()').to_s
    unless create_success == 'Y'
      runtime_error = parse_runtime_error_from_response(response: result_response_body)
      raise runtime_error if runtime_error.present?

      errors = self.parse_errors_from_response(response: result_response_body)
      raise BookingLib::Errors::BookingFailedException.new(error_code: TNTShipperLib::Errors::CREATE_BOOKING_FAILED, errors: errors, data: result_response_body)
    end

    consignment_reference = doc.xpath('/document/CREATE/CONREF/text()').to_s
    consignment_number    = doc.xpath('/document/CREATE/CONNUMBER/text()').to_s

    # check that shipping succeeded
    ship_success = doc.xpath('/document/SHIP/CONSIGNMENT/SUCCESS/text()').to_s
    unless ship_success == 'Y'
      ExceptionMonitoring.report_message("TNT shipment did not succeed", context: {
        shipment_id: shipment.shipment_id,
        response_body: result_response_body,
      })
      errors = self.parse_errors_from_response(response: result_response_body)
      raise BookingLib::Errors::BookingFailedException.new(error_code: TNTShipperLib::Errors::SHIP_BOOKING_FAILED, errors: errors, data: result_response_body)
    end

    booking_reference = doc.xpath('/document/BOOK/CONSIGNMENT/BOOKINGREF/text()').to_s

    # create response
    booking = TNTShipperLib::Booking.new(access_id: access_id, shipment_id: shipment.shipment_id, consignment_reference: consignment_reference, consignment_number: consignment_number, booking_reference: booking_reference)
    return booking

  rescue => exception
    ExceptionMonitoring.report(exception)
    Rails.logger.error "TNTShipperLibError#book_shipment: #{exception.inspect}"

    if exception.is_a?(BookingLib::Errors::BookingFailedException) || exception.is_a?(BookingLib::Errors::RuntimeException)
      raise exception
    else
      raise BookingLib::Errors::BookingFailedException.new(error_code: TNTShipperLib::Errors::UNKNOWN_ERROR, errors: ["Exception message: #{exception.try(:message)}"], data: "Exception backtrace: #{exception.try(:backtrace).try(:inspect)}")
    end
  end

  # @param [TNTShipperLib::Booking] booking
  #
  # @return [TNTShipperLib::Booking]
  def get_awb_document(booking: nil)
    raise BookingLib::Errors::AwbDocumentFailedException.new(error_code: TNTShipperLib::Errors::ACCESS_ID_NOT_FOUND) if (booking.nil? || (booking.class.to_s != TNTShipperLib::Booking.to_s) || booking.access_id.blank?)

    begin
      label_response = @connection.post do |req|
        req.url(API_ENDPOINT)
        req.body = 'xml_in=' + 'GET_LABEL:' + booking.access_id
      end
    rescue
      errors = [BookingLib::Errors::APIError.new(code:"CF-TNT-NET", description: 'A connection problem occured')]
      raise BookingLib::Errors::BookingFailedException.new(error_code: TNTShipperLib::Errors::CONNECTION_FAILED, errors: errors)
    end

    if booking.shipment_id.blank?
      @label_pdf_file_path = SecureRandom.uuid + '.pdf'
    else
      @label_pdf_file_path = "#{booking.shipment_id}_awb_document.pdf"
    end

    tnt_print = TNTPrint.new(xml_string: label_response.body)
    pdf = nil

    begin
      tnt_print.generate_pdf!(@label_pdf_file_path)
    rescue TNTPrint::PDFGenerationTimeoutError => e
      ExceptionMonitoring.report(e)
      raise BookingLib::Errors::AwbDocumentFailedException.new(error_code: TNTShipperLib::Errors::PDF_TRANSFORM_ERROR)
    rescue => e
      ExceptionMonitoring.report(e)
      raise BookingLib::Errors::AwbDocumentFailedException.new(error_code: TNTShipperLib::Errors::AWB_XML_FAILURE, data: label_response.body)
    end

    new_booking = nil
    if booking.is_a?(TNTShipperLib::Booking)
      new_booking = TNTShipperLib::Booking.new(access_id: booking.access_id, shipment_id: booking.shipment_id, consignment_reference: booking.consignment_reference, consignment_number: booking.consignment_number, awb_file_path: @label_pdf_file_path, consignment_note_file_path: booking.consignment_note_file_path)
    elsif booking.is_a?(BookingLib::Booking)
      new_booking = BookingLib::Booking.new(awb: booking.awb, awb_file_path: @label_pdf_file_path, consignment_note_file_path: booking.consignment_note_file_path)
    end

    return new_booking
  rescue => exception
    ExceptionMonitoring.report(exception)
    Rails.logger.error "TNTShipperLibError#get_awb_document: \n #{exception.inspect}"

    if exception.is_a?(BookingLib::Errors::AwbDocumentFailedException)
      raise exception
    else
      raise BookingLib::Errors::AwbDocumentFailedException.new(error_code: TNTShipperLib::Errors::UNKNOWN_ERROR)
    end
  end

  # @param [TNTShipperLib::Booking] booking
  #
  # @return [TNTShipperLib::Booking]
  def get_consignment_note_document(booking: nil)
    raise BookingLib::Errors::ConsignmentNoteFailedException.new(error_code: TNTShipperLib::Errors::ACCESS_ID_NOT_FOUND) if (booking.nil? || (booking.class.to_s != TNTShipperLib::Booking.to_s) || booking.access_id.blank?)

    begin
      connote_response = @connection.post do |req|
        req.url(API_ENDPOINT)
        req.body = 'xml_in=' + 'GET_CONNOTE:' + booking.access_id
      end
    rescue
      errors = [BookingLib::Errors::APIError.new(code:"CF-TNT-NET", description: 'A connection problem occured')]
      raise BookingLib::Errors::BookingFailedException.new(error_code: TNTShipperLib::Errors::CONNECTION_FAILED, errors: errors)
    end

    if booking.shipment_id.blank?
      @connote_pdf_file_path = SecureRandom.uuid + '.pdf'
    else
      @connote_pdf_file_path = "#{booking.shipment_id}_consignment_note.pdf"
    end

    tnt_print = TNTPrint.new(xml_string: connote_response.body)
    pdf = nil

    begin
      tnt_print.generate_pdf!(@connote_pdf_file_path)
    rescue TNTPrint::PDFGenerationTimeoutError => e
      ExceptionMonitoring.report(e)
      raise BookingLib::Errors::ConsignmentNoteFailedException.new(error_code: TNTShipperLib::Errors::PDF_TRANSFORM_ERROR)
    rescue => e
      ExceptionMonitoring.report(e)
      raise BookingLib::Errors::ConsignmentNoteFailedException.new(error_code: TNTShipperLib::Errors::CONSIGNMENT_XML_FAILURE, data: connote_response.body)
    end

    new_booking = nil
    if booking.is_a?(TNTShipperLib::Booking)
      new_booking = TNTShipperLib::Booking.new(access_id: booking.access_id, shipment_id: booking.shipment_id, consignment_reference: booking.consignment_reference, consignment_number: booking.consignment_number, awb_file_path: booking.awb_file_path, consignment_note_file_path: @connote_pdf_file_path)
    elsif booking.is_a?(BookingLib::Booking)
      new_booking = BookingLib::Booking.new(awb: booking.awb, awb_file_path: booking.awb_file_path, consignment_note_file_path: @connote_pdf_file_path)
    end

    return new_booking
  rescue => exception
    ExceptionMonitoring.report(exception)
    Rails.logger.error "TNTShipperLibError#get_consignment_note_document: \n #{exception.inspect}"

    if exception.is_a?(BookingLib::Errors::ConsignmentNoteFailedException)
      raise exception
    else
      raise BookingLib::Errors::ConsignmentNoteFailedException.new(error_code: TNTShipperLib::Errors::UNKNOWN_ERROR)
    end
  end

  # @param booking[Booking]
  def remove_temporary_files(booking: nil)
    File.delete(booking.awb_file_path) unless booking.awb_file_path.nil?
    File.delete(booking.consignment_note_file_path) unless booking.consignment_note_file_path.nil?
  rescue => exception
    ExceptionMonitoring.report(exception)
    raise BookingLib::Errors::RemoveTemporaryFilesFailedException.new(error_code: TNTShipperLib::Errors::UNKNOWN_ERROR)
  end

  #protected

  # @param response[String]
  # @return [Array<BookingLib::Errors::APIError>]
  def parse_errors_from_response(response: nil)
    doc = Nokogiri::XML(response)

    # iterate each error and extract code + description
    errors = doc.xpath('/document/ERROR').map do |error|
      code = error.xpath('./CODE/text()').to_s
      description = error.xpath('./DESCRIPTION/text()').to_s

      BookingLib::Errors::APIError.new(code: code, description: description)
    end

    return errors
  end

  # Checks the response for any runtime errors such as invalid credentials
  #
  def parse_runtime_error_from_response(response: nil)
    doc         = Nokogiri::XML(response)
    description = doc.xpath('/document/runtime_error/error_reason/text()').to_s

    if description.present?
      exception = BookingLib::Errors::RuntimeException.new(error_code: TNTShipperLib::Errors::RUNTIME_ERROR, description: description, data: response)
      return exception
    else
      return
    end
  end

  def transform_to_tnt_char_set(string)
    transliterated_string = I18n.transliterate(string)
    escaped_string        = xml_escape(transliterated_string)

    escaped_string
  end

  def xml_escape(string)
    REXML::Text.new(string, false, nil, false).to_s
  end

end

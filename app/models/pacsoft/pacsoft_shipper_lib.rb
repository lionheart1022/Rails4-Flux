# Perform bookings with Pacsoft
#
# Can book consignments with Post Danmark through Pacsofts API
# Requires an existing agreement with Pacsoft

require 'rexml/document'

class PacsoftShipperLib < BookingLib

  EMAIL_REGEX        = /(^$|^.*@.*\..*$)/i
  PHONE_NUMBER_REGEX = /^$|^(\+[0-9]{1,4})?[0-9]{4,}$/
  DPD_DEPOT          = '0502'


  module PartnerCodes
    PDK   = 'PDK'
    DPDDK = 'DPDDK'
  end

  module ServiceCodes
    module PostDk
      ERHVERVSPAKKE                    = 'PDKEP'
      PRIVATPAKKER_NORDEN              = 'P19DK'
      PRIVATPAKKER_NORDEN_MED_OMDELING = 'P19DK'
      DPD_CLASSIC                      = 'DPDDK'
    end
  end

  module Errors
    INVALID_ARGUMENT      = 'invalid_argument'
    CREATE_BOOKING_FAILED = 'create_booking_failed'
    UNKNOWN_ERROR         = 'unknown_error'

    class APIError
      attr_reader :code, :description

      def initialize(code: nil, description: nil)
        @code         = code
        @description  = description
      end

      def to_s
        "#{@code}: #{@description}"
      end
    end
  end

  class Credentials
    attr_reader :company, :password, :account

    def initialize(company: nil, password: nil, account: nil)
      @company  = company
      @password = password
      @account  = account
    end
  end

  class Booking < BookingLib::Booking
    attr_reader :access_id, :shipment_id, :consignment_reference, :consignment_number

    def initialize(access_id: nil, shipment_id: nil, consignment_reference: nil, consignment_number: nil, awb_file_path: nil, consignment_note_file_path: nil)
      @access_id              = access_id
      @shipment_id            = shipment_id
      @consignment_reference  = consignment_reference
      @consignment_number     = consignment_number

      super(awb: consignment_number, awb_file_path: awb_file_path, consignment_note_file_path: consignment_note_file_path)
    end
  end

  class Contact
    attr_reader :contact_id, :company_name, :attention, :email, :phone_number,
                :address_line1, :address_line2, :address_line3, :zip_code, :city, :country_code, :state_code

    def initialize(contact_id: nil, company_name: nil, attention: nil, email: nil, phone_number: nil, address_line1: nil, address_line2: nil, address_line3: nil, zip_code: nil, city: nil, country_code: nil, state_code: nil)
      @contact_id    = contact_id
      @company_name  = company_name
      @attention     = attention
      @email         = email
      @phone_number  = phone_number
      @address_line1 = address_line1
      @address_line2 = address_line2
      @address_line3 = address_line3
      @zip_code      = zip_code
      @city          = city
      @country_code  = country_code
      @state_code    = state_code
    end
  end

  class Shipment
    attr_reader :shipment_id, :created_at, :shipping_date, :number_of_packages,
                :package_dimensions, :dutiable, :customs_amount, :customs_currency,
                :customs_code, :description, :linkprintkey,
                :carrier_product_service, :carrier_product_supports_auto_book_delivery,
                :carrier_product, :reference

    def initialize(shipment_id: nil, created_at: nil, shipping_date: nil, number_of_packages: nil, package_dimensions: nil, dutiable: nil, customs_amount: nil, customs_currency: nil, customs_code: nil, description: nil, linkprintkey: nil, carrier_product: nil, carrier_product_service: nil, carrier_product_supports_auto_book_delivery: nil, reference: nil)
      @shipment_id             = shipment_id
      @created_at              = created_at
      @shipping_date           = shipping_date
      @number_of_packages      = number_of_packages
      @package_dimensions      = package_dimensions
      @dutiable                = dutiable
      @customs_amount          = customs_amount
      @customs_currency        = customs_currency
      @customs_code            = customs_code
      @description             = description
      @linkprintkey            = linkprintkey
      @carrier_product         = carrier_product
      @carrier_product_service = carrier_product_service
      @carrier_product_supports_auto_book_delivery = carrier_product_supports_auto_book_delivery
      @reference               = reference
    end
  end

  API_HOST      = 'https://www.unifaunonline.com'
  API_ENDPOINT  = '/ufoweb/order'

  def initialize
    @connection = Faraday.new(:url => API_HOST) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  # @param [PacsoftShipperLib::Shipment] shipment
  # @param [PacsoftShipperLib::Contact] recipient
  # @param [PacsoftShipperLib::Contact] sender
  #
  # @return [PacsoftShipperLib::Booking]
  def book_shipment(credentials: nil, shipment: nil, sender: nil, recipient: nil)

    # Validate argument types
    arg_errors = []
    arg_errors << [credentials, PacsoftShipperLib::Credentials] unless credentials.is_a?(PacsoftShipperLib::Credentials)
    arg_errors << [shipment, PacsoftShipperLib::Shipment] unless shipment.is_a?(PacsoftShipperLib::Shipment)
    arg_errors << [sender, PacsoftShipperLib::Contact] unless sender.is_a?(PacsoftShipperLib::Contact)
    arg_errors << [recipient, PacsoftShipperLib::Contact] unless recipient.is_a?(PacsoftShipperLib::Contact)

    unless arg_errors.empty?
      arg_errors_strings = arg_errors.map {|e| "#{e[0].class.to_s} should have been a #{e[1]}" }
      raise BookingLib::Errors::BookingLibException.new(error_code: PacsoftShipperLib::Errors::INVALID_ARGUMENT, errors: arg_errors_strings)
    end

    # validate argument data
    validation_errors = []

    # shipment
    validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-1", description: "Shipment date must be at most one week in the future") if shipment.shipping_date < Date.today || shipment.shipping_date > (Date.today+1.week)

    # package dimensions
    validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-2", description: "Shipment must contain at least one package") if shipment.package_dimensions.dimensions.count == 0
    shipment.package_dimensions.dimensions.each_with_index do |package_dimension, idx|
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-3", description: "Package #{idx+1} must have non-zero dimensions") if package_dimension.length == 0 || package_dimension.width == 0 || package_dimension.height == 0 || package_dimension.weight == 0
    end

    # description
    validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-4", description: "Description must be present") unless shipment.description.present?

    # Sender + recipient
    [sender, recipient].each_with_index do |contact, idx|
      contact_name = ["Sender", "Recipient"][idx]
      # present
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}00", description: "#{contact_name} company name must be present") unless contact.company_name.present?
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}01", description: "#{contact_name} attention name must be present") unless contact.attention.present?
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}02", description: "#{contact_name} address line 1 must be present") unless contact.address_line1.present?
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}03", description: "#{contact_name} zip code must be present") unless contact.zip_code.present?
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}04", description: "#{contact_name} city must be present") unless contact.city.present?
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}05", description: "#{contact_name} country must be present") unless contact.country_code.present?
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}06", description: "#{contact_name} email not formatted properly") unless contact.email =~ EMAIL_REGEX
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}07", description: "#{contact_name} phone number not formatted properly") unless contact.phone_number.gsub(/\s+/, "") =~ PHONE_NUMBER_REGEX

      # logic
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}06", description: "#{contact_name} country must be Denmark") if contact.country_code != "dk" && !shipment.carrier_product.try('international?')
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}07", description: "Address Line3 is not supported for Post Danmark shipments") if contact.address_line3.present?


      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}08", description: "#{contact_name} company name cannot be longer than 50 characters") if contact.company_name.length > 50
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}09", description: "#{contact_name} address line 1 cannot be longer than 30 characters") if contact.address_line1.length > 30
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}10", description: "#{contact_name} address line 2 cannot be longer than 30 characters") if contact.address_line2.length > 30
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}11", description: "#{contact_name} city cannot be longer than 30 characters") if contact.city.length > 30
      validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-#{idx+1}12", description: "#{contact_name} zip code cannot be longer than 9 characters") if contact.zip_code.length > 9
    end

    validation_errors << BookingLib::Errors::APIError.new(code:"CF-PAC-007", description: "Reference field cannot exceed 60 characters") if shipment.reference.length > 60

    # raise error
    unless validation_errors.empty?
      Rails.logger.debug "validation errors #{validation_errors}"
      raise BookingLib::Errors::BookingFailedException.new(error_code: PacsoftShipperLib::Errors::INVALID_ARGUMENT, errors: validation_errors)
    end

    # Load request template
    shipment_request_xml_template = ERB.new(File.read(path_to_template(filename: 'post_dk_shipper_template.xml.erb')))

    # Populate template
    shipment_request_xml = shipment_request_xml_template.result(binding)

    # Book shipment
    book_response = @connection.post do |req|
      request = API_ENDPOINT + "?user=#{credentials.company}&pin=#{credentials.password}&developerid=#{credentials.account}&session=po_DK&type=xml"
      req.url(request)
      req.headers['Content-Type'] = 'text/xml'
      req.body = shipment_request_xml
    end

    # Get booking result
    book_response_body = book_response.body

    Rails.logger.debug book_response_body
    doc = Nokogiri::XML(book_response_body)
    response_code = doc.xpath("//response/val[@n='status']").try(:text)

    unless response_code == '201'
      errors = self.parse_errors_from_response(response: book_response_body)
      raise BookingLib::Errors::BookingFailedException.new(error_code: PacsoftShipperLib::Errors::CREATE_BOOKING_FAILED, errors: errors, data: book_response_body)
    end

  rescue => exception
    Rails.logger.error "PacsoftShipperLibError: #{exception.inspect}"
    ExceptionMonitoring.report(exception)

    if exception.is_a?(BookingLib::Errors::BookingFailedException)
      raise exception
    else
      raise BookingLib::Errors::BookingFailedException.new(error_code: PacsoftShipperLib::Errors::UNKNOWN_ERROR)
    end
  end

  # @param response[String]
  # @return [Array<PacsoftShipperLib::Errors::APIError>]
  def parse_errors_from_response(response: nil)
    errors = []
    doc = Nokogiri::XML(response)

    # Only one error in Pacsoft response
    code = doc.xpath("//response/val[@n='status']").try(:text)
    description = doc.xpath("//response/val[@n='message']").try(:text)
    errors << PacsoftShipperLib::Errors::APIError.new(code: code, description: description)

    return errors
  end

  def transform_to_post_dk_char_set(string)
    xml_escape(string)
  end

  def xml_escape(string)
    REXML::Text.new(string, false, nil, false).to_s
  end
end

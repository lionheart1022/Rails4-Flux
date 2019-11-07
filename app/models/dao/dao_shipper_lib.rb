# Perform bookings with DOA
#
# Can book consignments with DOA through their API
# Requires an existing agreement with DOA
#

require 'rexml/document'
require 'uri'

class DAOShipperLib < BookingLib

  module ServiceCodes
    module Domestic
    end

    module International
    end
  end

  module Errors
    ATTRIBUTE_NOT_SUPPORTED = 'attribute_not_supported'
    INVALID_ARGUMENT    = 'invalid_argument'
    BOOKING_FAILED      = 'booking_failed'
    AWB_FAILED          = 'awb_failed'
    UNKNOWN_ERROR       = 'unknown_error'
    PAKKESHOP_NOT_FOUND = 'pakkeshop_not_found'
  end

  module Responses
    ERROR   = 'FEJL'
    SUCCESS = 'OK'
  end

  class Credentials
    attr_reader :account, :password

    def initialize(account: nil, password: nil)
      @account  = account
      @password = password
    end
  end

  class Booking < BookingLib::Booking
    attr_reader :barcode, :shipment_id, :shop_id

    def initialize(barcode: nil, shipment_id: nil, shop_id: nil)
      @barcode     = barcode
      @shipment_id = shipment_id
      @shop_id     = shop_id

      super()
    end
  end

  class Contact
    attr_reader :company_name, :attention, :email, :phone_number_dial_code, :phone_number_number, :address_line1, :address_line2, :zip_code, :city, :country_code, :state_code

    def initialize(company_name: nil, attention: nil, email: nil, phone_number_dial_code: nil, phone_number_number: nil, address_line1: nil, address_line2: nil, zip_code: nil, city: nil, country_code: nil, state_code: nil)
      @company_name           = company_name
      @attention              = attention
      @email                  = email
      @phone_number_dial_code = phone_number_dial_code
      @phone_number_number    = phone_number_number
      @address_line1          = address_line1
      @address_line2          = address_line2
      @zip_code               = zip_code
      @city                   = city
      @country_code           = country_code
      @state_code             = state_code
    end
  end

  class Shipment
    attr_reader :shipment_id, :shipping_date, :number_of_packages, :package_dimensions, :description, :carrier_product, :parcelshop_id

    def initialize(shipment_id: nil, shipping_date: nil, number_of_packages: nil, package_dimensions: nil, description: nil, carrier_product: nil, parcelshop_id: nil)
      @shipment_id        = shipment_id
      @shipping_date      = shipping_date
      @number_of_packages = number_of_packages
      @package_dimensions = package_dimensions
      @description        = description
      @carrier_product    = carrier_product
      @parcelshop_id      = parcelshop_id
    end
  end

  API_HOST                = 'https://api.dao.as'
  API_DIREKT_ENDPOINT     = '/DAODirekte/leveringsordre.php?'
  API_NAT_XPRESS_ENDPOINT = '/DAONatXpress/ShippingOrder.php?'
  API_PAKKESHOP_ENDPOINT  = '/DAOPakkeshop/leveringsordre.php?'
  API_PAKKESHOP_RETURN_ENDPOINT = '/DAOPakkeshop/returordre.php?'
  API_NEAREST_PAKKESHOP   = '/DAOPakkeshop/FindPakkeshop.php?'
  API_AWB_ENDPOINT        = '/HentLabel.php?'

  TRACKANDTRACE_ENDPOINT = 'http://www.tracktrace.dk/index.php?'

  def initialize
    @connection = Faraday.new(:url => API_HOST, timeout: 60, open_timeout: 60) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  def book_shipment(credentials: nil, shipment: nil, sender: nil, recipient: nil, test: nil)
    carrier_product = shipment.carrier_product

    if recipient.address_line3.present?
      message = 'Address Line3 is not supported for DAO shipments'
      error   = BookingLib::Errors::APIError.new(code: DAOShipperLib::Errors::ATTRIBUTE_NOT_SUPPORTED, description: message)
      raise BookingLib::Errors::BookingFailedException.new(error_code: DAOShipperLib::Errors::BOOKING_FAILED, errors: [error], data: nil)
    end

    case carrier_product.class.to_s
      when DAODirektCarrierProduct.to_s
        book_direkt(credentials: credentials, shipment: shipment, sender: sender, recipient: recipient, test: test)
      when DAOPakkeshopCarrierProduct.to_s
        book_pakkeshop(credentials: credentials, shipment: shipment, sender: sender, recipient: recipient, test: test)
      when DAOPakkeshopReturnCarrierProduct.to_s
        book_pakkeshop_return(credentials: credentials, shipment: shipment, sender: sender, recipient: recipient, test: test)
      else
        raise BookingLib::Errors::BookingFailedException.new('Unknown carrier product requested')
      end

  end

  def book_direkt(credentials: nil, shipment: nil, sender: nil, recipient: nil, test: false)

    # load query string
    params = self.booking_url_params(credentials: credentials, sender: sender, recipient: recipient, shipment: shipment, test: test)
    request = API_DIREKT_ENDPOINT + params

    # book shipment

    book_response = @connection.post do |req|
      req.url(request)
    end

    book_response_body = book_response.body
    Rails.logger.debug "Response: \n#{API_DIREKT_ENDPOINT + params}"

    doc                = Nokogiri::XML(book_response_body)
    status             = doc.xpath('/daoapi/status/text()').text
    successful         = status == DAOShipperLib::Responses::SUCCESS

    if !successful
      error = parse_error_from_response(response: book_response_body)
      data  = "Request: \n#{request}\nResponse: \n#{book_response_body}"
      raise BookingLib::Errors::BookingFailedException.new(error_code: DAOShipperLib::Errors::BOOKING_FAILED, errors: [error], data: data)
    end

    barcode = doc.xpath('/daoapi/resultat/stregkode/text()').text
    Rails.logger.debug "DAOBarcode: #{barcode}"

    booking = Booking.new(barcode: barcode, shipment_id: shipment.shipment_id)
    return booking
  rescue => e
    Rails.logger.error "DAOShipperLibError#book_direkt: #{e.inspect}"
    raise e
  end

  def book_pakkeshop(credentials: nil, shipment: nil, sender: nil, recipient: nil, test: false)
    parcelshop_id = shipment.parcelshop_id
    parcelshop_id = self.find_closest_parcel_shop_id(credentials: credentials, recipient: recipient) if parcelshop_id.blank?

    params = self.booking_url_params(credentials: credentials, recipient: recipient, shipment: shipment, shop_id: parcelshop_id, test: test)
    request = API_PAKKESHOP_ENDPOINT + params

    # book shipment
    book_response = @connection.post do |req|
      req.url(request)
    end

    book_response_body = book_response.body
    Rails.logger.debug "Response: \n#{API_PAKKESHOP_ENDPOINT + params}"

    doc                = Nokogiri::XML(book_response_body)
    status             = doc.xpath('/daoapi/status/text()').text
    successful         = status == DAOShipperLib::Responses::SUCCESS

    if !successful
      error = parse_error_from_response(response: book_response_body)
      data  = "Request: \n#{request}\nResponse: \n#{book_response_body}"
      raise BookingLib::Errors::BookingFailedException.new(error_code: DAOShipperLib::Errors::BOOKING_FAILED, errors: [error], data: data)
    end

    barcode = doc.xpath('/daoapi/resultat/stregkode/text()').text
    Rails.logger.debug "DAOBarcode: #{barcode}"

    booking = Booking.new(barcode: barcode, shop_id: parcelshop_id, shipment_id: shipment.shipment_id)
    return booking
  rescue => e
    Rails.logger.error "DAOShipperLibError#book_pakkeshop: #{e.inspect}"
    raise e
  end

  def book_pakkeshop_return(credentials: nil, shipment: nil, sender: nil, recipient: nil, test: false)
    req_params =
      URI.encode_www_form(
        "kundeid" => credentials.account,
        "kode" => credentials.password,
        "postnr" => recipient.zip_code,
        "adresse" => "#{recipient.address_line1} #{recipient.address_line2}",
        "navn" => recipient.attention,
        "afsender" => sender.company_name,
        "afs_email" => sender.email,
        "type" => "withlabel",
        "test" => Rails.env.production? && !test ? "" : "1",
        "format" => "json",
      )

    req_uri = URI(API_PAKKESHOP_RETURN_ENDPOINT)
    req_uri.query = req_params

    booking_response = @connection.post do |req|
      req.url(req_uri.to_s)
    end

    booking_response_body = booking_response.body
    booking_json = JSON.parse(booking_response_body)
    successful = booking_json["status"] == DAOShipperLib::Responses::SUCCESS

    if !successful
      error = BookingLib::Errors::APIError.new(code: booking_json["fejlkode"], description: booking_json["fejltekst"])
      data = "Request: \n#{request}\nResponse: \n#{booking_response_body}"
      raise BookingLib::Errors::BookingFailedException.new(error_code: DAOShipperLib::Errors::BOOKING_FAILED, errors: [error], data: data)
    end

    barcode = booking_json["resultat"]["stregkode"]

    Booking.new(barcode: barcode, shop_id: nil, shipment_id: shipment.shipment_id)
  end

  def find_closest_parcel_shop_id(credentials: nil, recipient: nil)
    params  = self.nearby_pakkeshops_url(credentials: credentials, recipient: recipient)
    request = API_NEAREST_PAKKESHOP + params

    # find nearest pakkeshop
    pakkeshops_response = @connection.post do |req|
      Rails.logger.debug "DAORequest: #{request}"
      req.url(request)
    end

    pakkeshops_response_body = pakkeshops_response.body
    Rails.logger.debug "DAO Response: #{pakkeshops_response_body}"

    doc        = Nokogiri::XML(pakkeshops_response_body)
    status     = doc.xpath('/daoapi/status/text()').text
    successful = status == DAOShipperLib::Responses::SUCCESS

    if !successful
      error = parse_error_from_response(response: pakkeshops_response.body)
      data  = "Request: \n#{request}\nResponse: \n#{pakkeshops_response_body}"
      raise BookingLib::Errors::BookingFailedException.new(error_code: DAOShipperLib::Errors::BOOKING_FAILED, errors: [error], data: data)
    end

    pakkeshops = doc.xpath('/daoapi/resultat/pakkeshops/pakkeshops')
    nearest    = pakkeshops[0]
    shop_id    = nearest.xpath('./shopId/text()').text

    return shop_id
  end

  def get_awb_document(credentials: nil, booking: nil)
    params = awb_url_params(credentials: credentials, barcode: booking.barcode)
    request = API_AWB_ENDPOINT + params

    response = @connection.post do |req|
      req.url(request)
    end

    response_body = response.body
    doc           = Nokogiri::XML(response_body)
    status        = doc.xpath('/daoapi/status/text()').text
    successful    = status != DAOShipperLib::Responses::ERROR

    if !successful
      error = parse_error_from_response(response: response_body)
      data  = "Request: \n#{request}\nResponse: \n#{book_response_body}"
      raise BookingLib::Errors::BookingFailedException.new(error_code: DAOShipperLib::Errors::AWB_FAILED, errors: [error], data: data)
    end

    if booking.shipment_id.blank?
      pdf_file_path = SecureRandom.uuid + '.pdf'
    else
      pdf_file_path = "#{booking.shipment_id}_awb.pdf"
    end

    File.open(pdf_file_path, 'wb') do |f|
      f.write(response_body)
    end

    return pdf_file_path
  rescue => e
    Rails.logger.error "DAOShipperLibError#get_awb_document: #{e.inspect}"
    raise BookingLib::Errors::AwbDocumentFailedException.new(error_code: DAOShipperLib::Errors::AWB_FAILED, data: nil)
  end

  def booking_url_params(credentials: nil, sender: nil, recipient: nil, shipment: nil, shop_id: nil, test: false)
    package_dimension = shipment.package_dimensions.dimensions.first
    live              = Rails.env.production? && !test ? '' : 1

    weight            = package_dimension.weight_in_grams.ceil
    string = ''
    string << "kundeid=#{credentials.account}&"
    string << "kode=#{credentials.password}&"
    string << "shopid=#{shop_id}&" if shop_id.present?
    string << "postnr=#{recipient.zip_code}&"
    string << "adresse=#{recipient.address_line1} #{recipient.address_line2}&"
    string << "navn=#{recipient.attention}&"
    string << "mobil=#{recipient.phone_number}&"
    string << "email=#{recipient.email}&"
    string << "vaegt=#{weight}&"
    string << "l=#{package_dimension.length}&"
    string << "h=#{package_dimension.height}&"
    string << "b=#{package_dimension.width}&"
    string << "test=#{live}&"
    string << "format=xml"

    return string
  end

  def nearby_pakkeshops_url(credentials: nil, recipient: nil)
    string = ''
    string << "kundeid=#{credentials.account}&"
    string << "kode=#{credentials.password}&"
    string << "postnr=#{recipient.zip_code}&"
    string << "adresse=#{recipient.full_address}&"
    string << "antal=1&"
    string << "format=xml"
  end

  def awb_url_params(credentials: nil, barcode: nil)
    string = ''
    string << "kundeid=#{credentials.account}&"
    string << "kode=#{credentials.password}&"
    string << "stregkode=#{barcode}&"
    string << "papir=60x100&"
    string << "format=xml"

    return string
  end

  def parse_error_from_response(response: nil)
    doc           = Nokogiri::XML(response)
    error_code    = doc.xpath('/daoapi/fejlkode/text()').text
    error_message = doc.xpath('/daoapi/fejltekst/text()').text

    return BookingLib::Errors::APIError.new(code: error_code, description: error_message)
  end

  def remove_temporary_file(file_path: nil)
    File.delete(file_path)
  rescue => exception
    ExceptionMonitoring.report(exception)
    raise BookingLib::Errors::RemoveTemporaryFilesFailedException.new(error_code: DAOShipperLib::Errors::UNKNOWN_ERROR)
  end

  def get_endpoint(test: false)

  end

end

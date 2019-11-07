class BringShipperLib < BookingLib

  class Booking < BookingLib::Booking
    attr_reader :shipment_id, :awb, :awb_file_path

    def initialize(shipment_id: nil, awb: nil, awb_file_path: nil)
      @shipment_id = shipment_id

      super(awb: awb, awb_file_path: awb_file_path)
    end
  end

  class Credentials
    attr_reader :user_id, :customer_number, :api_key

    def initialize(user_id: nil, customer_number: nil, api_key: nil)
      @user_id         = user_id
      @customer_number = customer_number
      @api_key         = api_key
    end
  end

  API_HOST = 'https://api.bring.com/'
  API_ENDPOINT = '/booking/api/booking'

  module Errors
    SHIP_BOOKING_FAILED = 'ship_booking_failed'
    FILE_ERROR = 'file_error'
    ATTRIBUTE_NOT_SUPPORTED = 'attribute_not_supported'
  end

  module Codes
    module Services
      module Standard
        SERVICE_PAKKE          = 'SERVICEPAKKE'
        BPAKKE                 = 'BPAKKE_DOR-DOR'
        EKSPRESS               = 'EKSPRESS09'
        CARRYON_HOME           = 'CARRYON_HOMESHOPPING'
        CARRYON_HOME_BULK      = 'CARRYON_HOMESHOPPING_BULKSPLIT'
        CARRYON_HOME_BULK_HOME = 'CARRYON_HOMESHOPPING_BULKSPLIT_HOME'
        CARRYON_BUSINESS       = 'CARRYON_BUSINESS'
        PICKUP_PARCEL          = 'PICKUP_PARCEL'
      end

      module Return
        SERVICE_PAKKE          = 'SERVICEPAKKE_RETURSERVICE'
        BPAKKE                 = 'BPAKKE_DOR-DOR_RETURSERVICE'
        EKSPRESS               = 'EKSPRESS09_RETURSERVICE'
        CARRYON_HOME           = 'CARRYON_HOMESHOPPING_RETURN'
        CARRYON_HOME_BULK      = 'CARRYON_HOMESHOPPING_BULKRETURN'
        CARRYON_BUSINESS       = 'CARRYON_BUSINESS_RETURN'
      end
    end
  end

  def initialize
    host = BringShipperLib::API_HOST

    @connection = Faraday.new(:url => host) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  def book_shipment(credentials: nil, shipment: nil, sender: nil, recipient: nil, carrier_product: nil, test: nil)
    check_params(sender: sender, recipient: recipient)
    request  = prepare_request(credentials: credentials, shipment: shipment, sender: sender, recipient: recipient, carrier_product: carrier_product, test: test)

    response = @connection.post do |req|
      req.url(API_ENDPOINT)

      req.headers['Content-Type']       = 'application/json'
      req.headers['X-MyBring-API-Uid']  = credentials.user_id
      req.headers['X-MyBring-API-Key']  = credentials.api_key
      req.headers['X-Bring-Client-URL'] = 'http://example.org/shop'

      req.body = request
    end

    response_body = response.body
    errors = validate_response(response: response_body)

    if (errors.present?)
      Rails.logger.debug "\n\nBringBookingErrors: \n#{errors.inspect}"
      context = error_context(request, response_body)

      raise BookingLib::Errors::BookingFailedException.new(error_code: BringShipperLib::Errors::SHIP_BOOKING_FAILED, errors: errors, data: context)
    end

    booking = extract_data_and_build_booking(response: response_body, shipment: shipment)
  rescue  => e
    ExceptionMonitoring.report(e)

    Rails.logger.error("\nBringShipperLibError:\n#{e.inspect}\n")
    Rails.logger.error("\nBringStackTrace:\n#{e.backtrace.join("\n")}\n")
    raise e
  end

  def remove_temporary_files(booking)
    File.delete(booking.awb_file_path) unless booking.awb_file_path.nil?
    File.delete(booking.consignment_note_file_path) unless booking.consignment_note_file_path.nil?
  rescue => exception
    ExceptionMonitoring.report(exception)
    raise BookingLib::Errors::RemoveTemporaryFilesFailedException.new(error_code: BringShipperLib::Errors::FILE_ERROR)
  end

  private

    def check_params(sender: nil, recipient: nil)
      contacts = [sender, recipient]
      address_line3_is_present = contacts.detect { |contact| contact.address_line3.present? }

      if address_line3_is_present
        message = 'Address Line3 is not supported for Bring shipments'
        error   = BookingLib::Errors::APIError.new(code: BringShipperLib::Errors::ATTRIBUTE_NOT_SUPPORTED, description: message)
        raise BookingLib::Errors::BookingFailedException.new(error_code: BringShipperLib::Errors::SHIP_BOOKING_FAILED, errors: [error], data: nil)
      end
    end

    # Bring redirects through their own domain first
    def download_file_from_url(url: nil, shipment: nil)
      response     = Faraday.get(url)
      redirect_url = response.headers['location']

      # The use of `URI::DEFAULT_PARSER` is due to the redirect_url otherwise being invalid according to RFC3986.
      # The default parser follows the RFC2396 standard.
      # Basically the issue is that there are unescaped square brackets in the URL.
      # Bring has been notified about this issue and if they fix it, then we can remove this fix.
      response     = Faraday.get(URI::DEFAULT_PARSER.parse(redirect_url))
      data         = response.body
      path         = "#{Rails.root}/tmp/#{shipment.unique_shipment_id}-awb_document.pdf"

      pdf_file = File.open(path, 'wb') do |f|
        f.write(data)
      end

      return path
    end

    def extract_data_and_build_booking(response: nil, shipment: nil)
      doc = Nokogiri::XML.parse(response)
      awb = doc.xpath('//xmlns:consignmentNumber/text()').try(:text)
      url = doc.xpath('//xmlns:links/xmlns:labels/text()').try(:text)

      awb_file_path = download_file_from_url(url: url, shipment: shipment)

      booking = BringShipperLib::Booking.new(shipment_id: shipment.shipment_id, awb: awb, awb_file_path: awb_file_path)
    end

    def validate_response(response: nil)
      doc = Nokogiri::XML.parse(response)

      errors = doc.xpath('//xmlns:errors').map do |node|
        messages = node.xpath('./xmlns:error/xmlns:messages').map do |message_node|
          message_node.xpath('./xmlns:message/text()').try(:text)
        end

        code = node.xpath('./xmlns:error/xmlns:code/text()').try(:text)
        description = messages.join('. ')

        BookingLib::Errors::APIError.new(code: code, description: description)
      end

      errors
    end

    def prepare_request(credentials: nil, shipment: nil, sender: nil, recipient: nil, carrier_product: nil, test: nil)
      is_test = test || !Rails.env.production?

      d = shipment.shipping_date
      shipping_time = Time.new(d.year, d.month, d.day, 16, 0, 0) # default to 16:30 as we don't let customers specify time

      shipping_date_time = shipping_time.to_datetime
      unix_timestamp_in_milliseconds = shipping_date_time.strftime('%Q')

      packages = shipment.package_dimensions.dimensions.map do |dimensions|
        formatted_dimensions = { heightInCm: dimensions.height, widthInCm: dimensions.width, lengthInCm: dimensions.length }

        {
          weightInKg: dimensions.weight,
          goodsDescription: shipment.description,
          dimensions: formatted_dimensions
        }
      end

      service_id = shipment.return_label ? carrier_product.return_service : carrier_product.service

      services = nil
      if carrier_product.supports_notifications?
        services = {
          recipientNotification: {
            email: recipient.email,
            mobile: recipient.phone_number
          }
        }
      end

      pickup_point = nil
      if shipment.parcelshop_id.present?
        pickup_point = { 
          id: shipment.parcelshop_id,
          countryCode: recipient.country_code
        }
      end

      request = {
        schemaVersion: 1,
        testIndicator: is_test,
        consignments: [
          {
            shippingDateTime: unix_timestamp_in_milliseconds,
            parties: {
              sender: {
                name: sender.company_name,
                addressLine: sender.address_line1,
                addressLine2: sender.address_line2,
                postalCode: sender.zip_code,
                city: sender.city,
                countryCode: sender.country_code,
                reference: shipment.reference,
                # additionalAddressInfo: "Hentes på baksiden etter klokken to",
                contact: {
                  name: sender.attention,
                  email: sender.email,
                  phoneNumber: sender.phone_number
                }
              },
              recipient: {
                name: recipient.company_name,
                addressLine: recipient.address_line1,
                addressLine2: recipient.address_line2,
                postalCode: recipient.zip_code,
                city: recipient.city,
                countryCode: recipient.country_code,
                # additionalAddressInfo: "Hentes på baksiden etter klokken to",
                contact: {
                  name: recipient.attention,
                  email: recipient.email,
                  phoneNumber: recipient.phone_number
                }
              },
              pickupPoint: pickup_point
            },
            product: {
              id: service_id,
              customerNumber: credentials.customer_number,
              services: services,
              customsDeclaration: nil
            },
            purchaseOrder: nil,
            # correlationId: "INTERNAL-123456",
            packages: packages
        }
      ],
    }

    json = request.to_json

    return json
  end

end

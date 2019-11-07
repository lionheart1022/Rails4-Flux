# UPSRequestInspector returns the API request body (of the confirm request).
# It does this in a hacky way because UPSShipperLib does not expose the request body as an isolated functionality.
# So instead a fake Faraday connection is injected before doing the first request (confirm) and this will catch the body
# and prevent actually making a real API call.
#
# Also there is a lot of duplication from UPSCarrierProductAutobookRequest - when we get the time we should get this cleaned up.
# But yeah, as stated above, the actual is problem that we cannot easily just generate the request body without making a request.
class UPSRequestInspector
  attr_reader :shipment

  def initialize(shipment)
    @shipment = shipment
  end

  def confirm_request_body
    carrier_product = shipment.carrier_product
    carrier_product_credentials = carrier_product.get_credentials
    credentials = UPSShipperLib::Credentials.new(
      access_token: carrier_product_credentials[:access_token],
      company: carrier_product_credentials[:company],
      password: carrier_product_credentials[:password],
      account: carrier_product_credentials[:account],
    )

    ups_sender, ups_recipient = [shipment.sender, shipment.recipient].map do |contact|
      contact.phone_number.blank? ? phone_number = '0000000000' : phone_number = contact.phone_number

      UPSShipperLib::Contact.new({
        company_name: contact.company_name,
        attention: contact.attention,
        email: contact.email,
        phone_number_number: phone_number,
        address_line1: contact.address_line1,
        address_line2: contact.address_line2,
        address_line3: contact.address_line3,
        zip_code: contact.zip_code,
        city: contact.city,
        country_code: contact.country_code,
        state_code: contact.state_code,
      })
    end

    ups_shipment = UPSShipperLib::Shipment.new({
      shipment_id: shipment.unique_shipment_id,
      shipping_date: shipment.shipping_date,
      number_of_packages: shipment.number_of_packages,
      package_dimensions: shipment.package_dimensions,
      customs_amount: shipment.customs_amount,
      customs_currency: shipment.customs_currency,
      customs_code: shipment.customs_code,
      description: shipment.description,
      dutiable: shipment.dutiable,
      reference: shipment.reference,
    })

    ups_shipping_options = UPSShipperLib::ShippingOptions.new({
      service_code: carrier_product.service,
      documents_only: carrier_product.ups_documents_only?,
      letter: carrier_product.ups_letter?,
      import: carrier_product.import?,
      packaging_code: carrier_product.packaging_code
    })

    if carrier_product.ups_return_service?
      ups_shipping_options.return_service_code = carrier_product.ups_return_service_code
    elsif carrier_product.import?
      ups_shipping_options.return_service_code = UPSShipperLib::ReturnServiceCodes::PRL
    else
      # From UPS docs: "QV Ship Notification is allowed for forward moving shipments only."
      ups_shipping_options.notification_code = UPSShipperLib::NotificationCodes::SHIP_NOTIFICATION
    end

    test_connection = Faraday.new do |builder|
      builder.adapter :test do |stub|
        stub.post('/ups.app/xml/ShipConfirm') do |env|
          raise IntentionalExceptionWithRequestData.new("This is intentional", env: env)
        end
      end
    end

    ups_shipper = UPSShipperLib.new
    ups_shipper.instance_variable_set(:@connection, test_connection)

    begin
      booking = ups_shipper.book_shipment(credentials: credentials, shipment: ups_shipment, sender: ups_sender, recipient: ups_recipient, shipping_options: ups_shipping_options)
    rescue IntentionalExceptionWithRequestData => e
      e.request_body
    else
      raise "You should not reach here"
    end
  end

  class IntentionalExceptionWithRequestData < BookingLib::Errors::BookingFailedException
    attr_reader :env

    def initialize(msg, env:)
      @env = env
      super(error_code: nil, errors: nil, data: nil)
    end

    def request_body
      env[:body]
    end
  end
end

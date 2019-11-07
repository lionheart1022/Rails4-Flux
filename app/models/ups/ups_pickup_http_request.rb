class UPSPickupHTTPRequest
  API_PROD_HOST = "https://onlinetools.ups.com"
  API_TEST_HOST = "https://wwwcie.ups.com"
  API_ENDPOINT = "/rest/Pickup"

  # Base validation error class
  class ValidationError < StandardError
  end

  # Class for validation errors which the user could have caused (for instance by not providing mandatory information)
  class UserValidationError < ValidationError
  end

  def self.build(credentials:, pickup:, shipment:)
    pickup_request = new

    pickup_request.username = credentials.company
    pickup_request.password = credentials.password
    pickup_request.access_license_number = credentials.access_token

    pickup_request.date_info = DateInfo.new(
      pickup_date: pickup.pickup_date,
      ready_time: pickup.from_time,
      close_time: pickup.to_time,
    )

    combined_address_line = [
      pickup.contact.address_line1,
      pickup.contact.address_line2,
      pickup.contact.address_line3,
    ].reject(&:blank?).join("; ")

    pickup_request.address = Address.new(
      company_name: pickup.contact.company_name,
      contact_name: pickup.contact.attention,
      address_line: combined_address_line,
      postal_code: pickup.contact.zip_code,
      city: pickup.contact.city,
      country_code: pickup.contact.country_code,
      state_province: pickup.contact.state_code,
      phone_number: shipment.sender.phone_number,
      pickup_point: pickup.description,
    )
    pickup_request.pieces << Piece.new(
      service_code: shipment.carrier_product.service,
      quantity: shipment.number_of_packages,
      destination_country_code: shipment.recipient.country_code,
    )

    pickup_request
  end

  attr_accessor :username, :password, :access_license_number
  attr_accessor :date_info
  attr_accessor :address
  attr_accessor :pieces

  def initialize(params = {})
    self.endpoint = params.delete(:endpoint) || API_ENDPOINT
    self.connection = params.delete(:connection) || begin
      Faraday.new(url: Rails.env.production? ? API_PROD_HOST : API_TEST_HOST) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
      end
    end

    self.pieces = []

    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def book_pickup!
    validate!

    response = connection.post do |req|
      req.url(endpoint)
      req["Content-Type"] = "application/json"
      req.body = request_body
    end

    UPSPickupResponse.parse(response.body)
  end

  def to_builder!
    validate!

    to_builder
  end

  def validate!
    if username.blank?
      raise ValidationError, "Required attribute `username` is missing"
    end

    if password.blank?
      raise ValidationError, "Required attribute `password` is missing"
    end

    if access_license_number.blank?
      raise ValidationError, "Required attribute `access_license_number` is missing"
    end

    %w{
      date_info
      address
    }.each do |attr_name|
      attr = public_send(attr_name)

      if !attr
        raise ValidationError, "Required attribute `#{attr}` is missing"
      end

      attr.validate!
    end

    if Array(pieces).blank?
      raise ValidationError, "No pieces have been specified"
    end
  end

  private

  def request_body
    to_builder.target!
  end

  def to_builder
    Jbuilder.new do |json|
      json.UPSSecurity do
        json.UsernameToken do
          json.Username username
          json.Password password
        end

        json.ServiceAccessToken do
          json.AccessLicenseNumber access_license_number
        end
      end

      json.PickupCreationRequest do
        json.Request do
          json.TransactionReference do
            json.CustomerContext nil
          end
        end

        json.RatePickupIndicator "N"
        json.TaxInformationIndicator "N"

        json.PickupDateInfo do
          json.CloseTime date_info.formatted_close_time
          json.ReadyTime date_info.formatted_ready_time
          json.PickupDate date_info.formatted_pickup_date
        end

        json.PickupAddress do
          json.CompanyName address.company_name
          json.ContactName address.contact_name
          json.AddressLine address.address_line
          json.City address.city
          json.StateProvince address.state_province if address.state_province?
          json.PostalCode address.postal_code
          json.CountryCode address.country_code
          json.ResidentialIndicator "N"
          json.PickupPoint address.pickup_point if address.pickup_point?
          json.Phone do
            json.Number address.phone_number
          end
        end

        json.AlternateAddressIndicator "N"
        json.ShippingLabelsAvailable "Y" # This element should be set to “Y” in the request to indicate that user has pre-printed shipping labels for all the packages; otherwise, this will be treated as false.

        json.PickupPiece Array(pieces) do |piece|
          json.ServiceCode piece.padded_service_code
          json.Quantity piece.quantity.to_s
          json.DestinationCountryCode piece.destination_country_code
          json.ContainerCode piece.container_code
        end

        json.OverweightIndicator "N"
        json.PaymentMethod "00" # 00 = No payment needed
      end
    end
  end

  attr_accessor :connection, :endpoint

  class DateInfo
    PICKUP_DATE_FORMAT = "%Y%m%d".freeze
    TIME_FORMAT_PATTERN = /\A(?<hours>[0-1][0-9]|2[0-3]):(?<minutes>[0-5][0-9])\z/

    attr_accessor :close_time
    attr_accessor :ready_time
    attr_accessor :pickup_date

    def initialize(params = {})
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def validate!
      if pickup_date.blank?
        raise ValidationError, "Pickup date is missing"
      end

      if !pickup_date.respond_to?(:to_date)
        raise ValidationError, "Pickup date is not a date object"
      end

      if ready_time.blank?
        raise ValidationError, "Ready-time is missing"
      end

      if !valid_time?(ready_time)
        raise ValidationError, "Ready-time has invalid format"
      end

      if close_time.blank?
        raise ValidationError, "Close-time is missing"
      end

      if !valid_time?(close_time)
        raise ValidationError, "Close-time has invalid format"
      end
    end

    def formatted_close_time
      format_time(close_time)
    end

    def formatted_ready_time
      format_time(ready_time)
    end

    def formatted_pickup_date
      pickup_date ? pickup_date.strftime(PICKUP_DATE_FORMAT) : nil
    end

    private

    def valid_time?(time)
      time && TIME_FORMAT_PATTERN.match(time) != nil
    end

    def format_time(time)
      if time && match = TIME_FORMAT_PATTERN.match(time)
        "#{match[:hours]}#{match[:minutes]}"
      end
    end
  end

  class Address
    attr_accessor :company_name
    attr_accessor :contact_name
    attr_accessor :address_line
    attr_accessor :city
    attr_accessor :state_province
    attr_accessor :postal_code
    attr_accessor :country_code
    attr_accessor :phone_number
    attr_accessor :pickup_point

    def initialize(params = {})
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def validate!
      if company_name.blank?
        raise UserValidationError, "[Address] Company name is required"
      end

      if contact_name.blank?
        raise UserValidationError, "[Address] Contact name is required"
      end

      if address_line.blank?
        raise UserValidationError, "[Address] Address line is required"
      end

      if city.blank?
        raise UserValidationError, "[Address] City is required"
      end

      if country_code.blank?
        raise ValidationError, "[Address] Country code is required"
      end

      if phone_number.blank?
        raise UserValidationError, "[Address] Phone number is required"
      end
    end

    def state_province?
      state_province.present?
    end

    def pickup_point?
      pickup_point.present?
    end
  end

  class Piece
    attr_accessor :service_code
    attr_accessor :quantity
    attr_accessor :destination_country_code
    attr_accessor :container_code

    def initialize(params = {})
      self.container_code = "01" # 01 = PACKAGE
      self.quantity = 1

      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def validate!
      if service_code.blank?
        raise ValidationError, "[Piece] Service code is required"
      end

      if quantity.blank?
        raise ValidationError, "[Piece] Quantity is required"
      end

      if destination_country_code.blank?
        raise ValidationError, "[Piece] Destination country code is required"
      end

      if container_code.blank?
        raise ValidationError, "[Piece] Container code is required"
      end
    end

    def padded_service_code
      service_code ? service_code.rjust(3, "0") : nil
    end
  end
end

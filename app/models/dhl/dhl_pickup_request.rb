class DHLPickupRequest
  API_PROD_HOST = "https://xmlpi-ea.dhl.com/".freeze
  API_TEST_HOST = "https://xmlpitest-ea.dhl.com/".freeze
  API_ENDPOINT = "/XMLShippingServlet".freeze

  REGION_CODE_MAPPING = {
    :asia_pacific => "AP", # Asia Pacific + Emerging Market
    :europe => "EU", # Europe (EU + Non-EU)
    :americas => "AM", # Americas (LatAm + US + CA)
  }.freeze
  REGION_CODES = REGION_CODE_MAPPING.values.freeze
  MESSAGE_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S%:z".freeze # e.g. 2002-12-02T13:23:18-07:00

  # Base validation error class
  class ValidationError < StandardError
  end

  # Class for validation errors which the user could have caused (for instance by not providing mandatory information)
  class UserValidationError < ValidationError
  end

  attr_accessor :credentials
  attr_accessor :message_time, :message_reference
  attr_accessor :region_code
  attr_accessor :requestor
  attr_accessor :place
  attr_accessor :pickup
  attr_accessor :pickup_contact

  def self.build(credentials:, pickup:, shipment:)
    pickup_request = new

    pickup_request.credentials = credentials
    pickup_request.requestor = Requestor.new(
      account_number: credentials.company,
      contact_person_name: pickup.contact.attention,
      contact_phone: shipment.sender.phone_number,
      company_name: pickup.contact.company_name,
      address_1: pickup.contact.address_line1,
      address_2: pickup.contact.address_line2,
      address_3: pickup.contact.address_line3,
      city: pickup.contact.city,
      country_code: pickup.contact.country_code,
    )
    pickup_request.place = Place.new(
      company_name: pickup.contact.company_name,
      address_1: pickup.contact.address_line1,
      address_2: pickup.contact.address_line2,
      address_3: pickup.contact.address_line3,
      postal_code: pickup.contact.zip_code,
      city: pickup.contact.city,
      country_code: pickup.contact.country_code,
      state_code: pickup.contact.state_code,
      package_location: pickup.description,
    )
    pickup_request.pickup = Pickup.new(
      pickup_date: pickup.pickup_date,
      ready_by_time: pickup.from_time,
      close_time: pickup.to_time,
    )
    pickup_request.pickup_contact = PickupContact.new(
      person_name: pickup.contact.attention,
      phone: shipment.sender.phone_number,
    )

    pickup_request
  end

  def initialize(params = {})
    self.connection = params.delete(:connection) || begin
      Faraday.new(url: Rails.env.production? ? API_PROD_HOST : API_TEST_HOST) do |faraday|
        faraday.request :url_encoded # form-encode POST params
        faraday.response :logger # log requests to STDOUT
        faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
      end
    end
    self.endpoint = params.delete(:endpoint) || API_ENDPOINT

    # Set defaults
    self.message_time = Time.now
    self.message_reference = "0" * 31 # Not really used for anything, so we're just setting it to a string of 31 zeros
    self.region_code_symbol = :europe

    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def book_pickup!
    validate!

    response = connection.post do |req|
      req.url(endpoint)
      req.body = request_body
    end

    DHLPickupResponse.parse(response.body)
  end

  def validate!
    if credentials.blank?
      raise ValidationError, "Required attribute `credentials` is missing"
    end

    if message_time.blank?
      raise ValidationError, "Required attribute `message_time` is missing"
    end

    if message_reference.blank?
      raise ValidationError, "Required attribute `message_reference` is missing"
    end

    if region_code.blank?
      raise ValidationError, "Required attribute `region_code` is missing"
    end

    if !REGION_CODES.include?(region_code)
      raise ValidationError, "Region code is not allowed (value: #{region_code})"
    end

    %w{
      requestor
      place
      pickup
      pickup_contact
    }.each do |attr_name|
      attr = public_send(attr_name)

      if !attr
        raise ValidationError, "Required attribute `#{attr}` is missing"
      end

      attr.validate!
    end

    true
  end

  def region_code_symbol=(value)
    self.region_code = value ? REGION_CODE_MAPPING.fetch(value.to_sym) : nil
  end

  def formatted_message_time
    message_time ? message_time.strftime(MESSAGE_TIME_FORMAT) : nil
  end

  private

  attr_accessor :connection, :endpoint

  def request_body
    builder = Nokogiri::XML::Builder.new do |xml|
      root_attrs = {
        "xmlns:req" => "http://www.dhl.com",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns" => "default",
        "xsi:schemaLocation" => "http://www.dhl.com book-pickup-global-req.xsd",
        "schemaVersion" => "3.0",
      }

      xml["req"].BookPURequest(root_attrs) do
        xml.Request do
          xml.ServiceHeader do
            xml.MessageTime formatted_message_time
            xml.MessageReference message_reference
            xml.SiteID credentials.account
            xml.Password credentials.password
          end

          xml.MetaData do
            xml.SoftwareName "XMLPI"
            xml.SoftwareVersion "6.2"
          end
        end

        xml.RegionCode region_code

        xml.Requestor do
          xml.AccountType requestor.account_type
          xml.AccountNumber requestor.account_number
          xml.RequestorContact do
            xml.PersonName requestor.contact_person_name
            xml.Phone requestor.contact_phone
          end
          xml.CompanyName requestor.company_name
          xml.Address1 requestor.address_1
          xml.Address2 requestor.address_2 if requestor.address_2?
          xml.Address3 requestor.address_3 if requestor.address_3?
          xml.City requestor.city
          xml.CountryCode requestor.country_code.upcase
        end

        xml.Place do
          xml.LocationType place.location_type
          xml.CompanyName place.company_name
          xml.Address1 place.address_1
          xml.Address2 place.address_2 if place.address_2?
          xml.Address3 place.address_3 if place.address_3?
          xml.PackageLocation place.package_location
          xml.City place.city
          xml.CountryCode place.country_code.upcase
          xml.PostalCode place.postal_code
          xml.StateCode place.state_code if place.state_code?
        end

        xml.Pickup do
          xml.PickupDate pickup.pickup_date
          xml.PickupTypeCode pickup.pickup_type_code
          xml.ReadyByTime pickup.ready_by_time
          xml.CloseTime pickup.close_time
        end

        xml.PickupContact do
          xml.PersonName pickup_contact.person_name
          xml.Phone pickup_contact.phone
        end
      end
    end

    builder
      .to_xml
      .sub(' xmlns="default"', "") # The DHL endpoint doesn't want the default namespace included
  end

  class Requestor
    DEFAULT_ACCOUNT_TYPE = "D".freeze # D, for DHL account

    attr_accessor :account_type, :account_number, :contact_person_name, :contact_phone, :company_name, :address_1, :address_2, :address_3, :city, :country_code

    def initialize(params = {})
      self.account_type = DEFAULT_ACCOUNT_TYPE

      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def validate!
      if account_type.blank?
        raise ValidationError, "Account type is missing"
      end

      if account_number.blank?
        raise UserValidationError, "Account number is missing"
      end

      if contact_person_name.blank?
        raise UserValidationError, "Contact person name is missing"
      end

      if contact_phone.blank?
        raise UserValidationError, "Contact phone is missing"
      end
    end

    def address_2?
      address_2.present?
    end

    def address_3?
      address_3.present?
    end
  end

  class Place
    LOCATION_TYPE_MAPPING = {
      :business => "B",
      :residence => "R",
      :business_slash_residence => "C",
    }.freeze
    LOCATION_TYPES = LOCATION_TYPE_MAPPING.values.freeze

    attr_accessor :location_type, :company_name, :address_1, :address_2, :address_3, :package_location, :city, :country_code, :postal_code, :state_code

    def initialize(params = {})
      self.location_type_symbol = :business

      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def location_type_symbol=(value)
      self.location_type = value ? LOCATION_TYPE_MAPPING.fetch(value.to_sym) : nil
    end

    def location_type_is?(*values)
      Array(values).all? do |value|
        LOCATION_TYPE_MAPPING[value.to_sym] == location_type
      end
    end

    def address_1?
      address_1.present?
    end

    def address_2?
      address_2.present?
    end

    def address_3?
      address_3.present?
    end

    def state_code?
      state_code.present?
    end

    def validate!
      if location_type.blank?
        raise ValidationError, "Location type is missing"
      end

      if !LOCATION_TYPES.include?(location_type)
        raise ValidationError, "Location type is not allowed (value: #{location_type})"
      end

      if location_type_is?(:business, :business_slash_residence) && company_name.blank?
        raise ValidationError, "Company name must be present when location type is B or C"
      end

      if address_1.blank?
        raise UserValidationError, "Address(1) is missing"
      end

      if package_location.blank?
        raise UserValidationError, "Package location is missing (example: front desk)"
      end

      if city.blank?
        raise UserValidationError, "City is missing"
      end

      if country_code.blank?
        raise UserValidationError, "Country code is missing"
      end
    end
  end

  class Pickup
    PICKUP_DATE_FORMAT = "%Y-%m-%d".freeze
    TIME_FORMAT_PATTERN = /\A([0-1][0-9]|2[0-3]):([0-5][0-9])\z/.freeze

    attr_accessor :pickup_date, :ready_by_time, :close_time

    def initialize(params = {})
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def formatted_pickup_date
      pickup_date ? pickup_date.strftime(PICKUP_DATE_FORMAT) : nil
    end

    def pickup_type_code
      if pickup_date.blank? || pickup_date.today?
        "S" # S = If pickup date is today
      else
        "A" # A = if pickup date is advance
      end
    end

    def validate!
      if pickup_date.blank?
        raise ValidationError, "Pickup date is missing"
      end

      if ready_by_time.blank?
        raise ValidationError, "Ready-by-time is missing"
      end

      if !valid_time?(ready_by_time)
        raise ValidationError, "Ready-by-time has invalid format"
      end

      if close_time.blank?
        raise ValidationError, "Close time is missing"
      end

      if !valid_time?(close_time)
        raise ValidationError, "Close time has invalid format"
      end
    end

    private

    def valid_time?(time)
      time && TIME_FORMAT_PATTERN.match(time) != nil
    end
  end

  class PickupContact
    attr_accessor :person_name, :phone

    def initialize(params = {})
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def validate!
      if person_name.blank?
        raise UserValidationError, "Person name is missing"
      end

      if phone.blank?
        raise UserValidationError, "Phone is missing"
      end
    end
  end
end

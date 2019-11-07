class GeodisBookingRequest
  include ActiveModel::Validations

  class << self
    def build_from_shipment(shipment)
      request = new

      request.authentication = shipment.carrier_product.geodis_credentials
      geodis_template = nil

      if shipment.pickup_relation && shipment.pickup_relation.auto?
        request.pickup = Pickup.new(
          date: shipment.pickup_relation.pickup_date,
          instructions: shipment.pickup_relation.description,
          earliest_time: shipment.pickup_relation.from_time,
          latest_time: shipment.pickup_relation.to_time,
          by_carrier: true,
        )
        geodis_template = shipment.carrier_product.geodis_template_with_pickup
      else
        request.pickup = Pickup.new(date: shipment.shipping_date)
        geodis_template = shipment.carrier_product.geodis_template_without_pickup
      end

      request.booking_method = BookingMethod.new(template: geodis_template)

      request.consignor = Consignor.new(
        name: shipment.sender.company_name,
        contact_person: shipment.sender.attention,
        address_1: shipment.sender.address_line1,
        address_2: shipment.sender.address_line2,
        post_code: shipment.sender.zip_code,
        city: shipment.sender.city,
        country_code: shipment.sender.country_code,
        phone_number: shipment.sender.phone_number,
      )

      request.consignee = Consignee.new(
        name: shipment.recipient.company_name,
        contact_person: shipment.recipient.attention,
        address_1: shipment.recipient.address_line1,
        address_2: shipment.recipient.address_line2,
        post_code: shipment.recipient.zip_code,
        city: shipment.recipient.city,
        country_code: shipment.recipient.country_code,
        phone_number: shipment.recipient.phone_number,
      )

      request.delivery = Delivery.new(
        name: shipment.recipient.company_name,
        contact_person: shipment.recipient.attention,
        address_1: shipment.recipient.address_line1,
        address_2: shipment.recipient.address_line2,
        post_code: shipment.recipient.zip_code,
        city: shipment.recipient.city,
        country_code: shipment.recipient.country_code,
        phone_number: shipment.recipient.phone_number,
        date: shipment.shipping_date,
      )

      request.transport_service = TransporService.new(
        reliable_to_duty: shipment.dutiable,
        value: shipment.customs_amount,
        currency: shipment.customs_currency,
      )

      request.goods_items = shipment.package_dimensions.dimensions.map do |package_dimension|
        GoodsItem.new(
          length: package_dimension.length,
          width: package_dimension.width,
          height: package_dimension.height,
          weight: package_dimension.weight,
          description: shipment.description,
          shipping_mark: shipment.remarks,
        )
      end

      request.senders_reference = shipment.reference

      request
    end
  end

  class ValidationFailed < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end
  end

  API_HOST = "https://portal.ff.geodis.com".freeze
  API_ENDPOINT = "/api/uploadxmlbooking.php".freeze

  XML_VERSION = "1".freeze

  DATE_FORMAT = "%Y-%m-%d".freeze

  attr_accessor :authentication
  attr_accessor :booking_method
  attr_accessor :consignor
  attr_accessor :consignee
  attr_accessor :delivery
  attr_accessor :pickup
  attr_accessor :transport_service
  attr_accessor :senders_reference
  attr_accessor :goods_items

  attr_accessor :test
  alias_method :test?, :test

  validates! :authentication, :booking_method, :consignee, :delivery, :pickup, :transport_service, presence: true
  validate :must_have_goods_items

  def initialize(params = {})
    self.connection = params.delete(:connection) || begin
      Faraday.new(url: API_HOST) do |faraday|
        faraday.request :url_encoded # form-encode POST params
        faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
      end
    end
    self.endpoint = params.delete(:endpoint) || API_ENDPOINT
    self.logger = get_tagged_logger(params.delete(:logger))

    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def book_shipment!
    validate!

    run_id = SecureRandom.hex

    xml = to_xml
    logger.tagged(run_id, Time.now, "Geodis", "request.body") { logger.debug(xml) }

    response = nil
    request_tms = Benchmark.measure do
      response = connection.post(endpoint, { xml: xml })
    end

    logger.tagged(run_id, Time.now, "Geodis", "request.time") { logger.info(request_tms.real) }
    logger.tagged(run_id, Time.now, "Geodis", "response.status") { logger.debug(response.status.inspect) }
    logger.tagged(run_id, Time.now, "Geodis", "response.headers") { logger.debug(response.headers.inspect) }

    booking_response = GeodisBookingResponse.parse(response.body)

    if booking_response.error? || booking_response.no_label?
      # Higher-level logging for errors or missing labels
      logger.tagged(run_id, Time.now, "Geodis", "response.body") { logger.error(response.body) }
    else
      logger.tagged(run_id, Time.now, "Geodis", "response.body") { logger.debug(response.body) }
    end

    booking_response
  end

  def to_xml
    if valid?
      to_builder.to_xml
    else
      nil
    end
  end

  def validate!
    if valid?
      true
    else
      raise ValidationFailed.new(errors)
    end
  end

  private

  attr_accessor :connection, :endpoint
  attr_accessor :logger

  def to_builder
    Nokogiri::XML::Builder.new(encoding: "utf-8") do |xml|
      xml.header(test: test_attr_value) do
        xml.authentication do
          xml.username authentication.username
          xml.password authentication.password
          xml.companyid authentication.company_id
          xml.xmlversion XML_VERSION
        end

        xml.consignmentlist do
          xml.consignment do
            xml.bookingmethod do
              xml.template booking_method.template
              xml.autobook booking_method.auto_book_value
              xml.label booking_method.label_value
              xml.labeltype booking_method.label_type
            end

            xml.part(role: "consignor") do
              xml.address do
                xml.id consignor.id
                xml.name consignor.name
                xml.address1 consignor.address_1
                xml.address2 consignor.address_2
                xml.postcode consignor.post_code
                xml.city consignor.city
                xml.countrycode consignor.country_code
              end

              xml.communication do
                xml.contactperson consignor.contact_person_value
                xml.phone consignor.phone_number
              end
            end

            xml.part(role: "consignee") do
              xml.address do
                xml.id consignee.id
                xml.name consignee.name
                xml.address1 consignee.address_1
                xml.address2 consignee.address_2
                xml.postcode consignee.post_code
                xml.city consignee.city
                xml.countrycode consignee.country_code
              end

              xml.communication do
                xml.contactperson consignee.contact_person_value
                xml.phone consignee.phone_number
              end
            end

            xml.part(role: "delivery") do
              xml.address do
                xml.id delivery.id
                xml.name delivery.name
                xml.address1 delivery.address_1
                xml.address2 delivery.address_2
                xml.postcode delivery.post_code
                xml.city delivery.city
                xml.countrycode delivery.country_code
              end

              xml.communication do
                xml.contactperson delivery.contact_person_value
                xml.phone delivery.phone_number
              end
            end

            xml.pdinstructions do
              xml.pickup do
                xml.pdate pickup.formatted_date
                xml.earliest pickup.earliest_time
                xml.latest pickup.latest_time
                xml.pinstructions pickup.instructions
                xml.pickupbycarrier pickup.by_carrier_value
              end

              xml.delivery do
                xml.ddate delivery.formatted_date
                xml.dinstructions delivery.instructions
              end
            end

            xml.transportservice do
              xml.reliabletoduty transport_service.reliable_to_duty_value
              xml.deliverytype transport_service.delivery_type if transport_service.delivery_type
              xml.value transport_service.value if transport_service.value
              xml.currency transport_service.currency if transport_service.currency
            end

            xml.references do
              xml.sendersreference senders_reference
            end

            goods_items.each do |goods_item|
              xml.goodsitem do
                xml.noofpackages goods_item.no_of_packages
                xml.width goods_item.width
                xml.length goods_item.length
                xml.height goods_item.height
                xml.weight goods_item.formatted_total_weight
                xml.packagecode goods_item.package_code
                xml.goodsdescription goods_item.description
                xml.shippingmark goods_item.shipping_mark
                xml.dangerous "no"
              end
            end
          end
        end
      end
    end
  end

  def must_have_goods_items
    if !goods_items.respond_to?(:to_ary)
      errors.add(:goods_items, "`goods_items` must be an array")
    end

    if goods_items.respond_to?(:to_ary) && goods_items.count == 0
      errors.add(:goods_items, "Must have at least one goods item")
    end
  end

  def test_attr_value
    test? ? "1" : "0"
  end

  def get_tagged_logger(logger = nil)
    if logger.nil?
      if Rails.env.development?
        log_path = Rails.root.join("log", "geodis.log")
        logger = Logger.new(log_path)
      else
        logger = Rails.logger
      end
    end

    ActiveSupport::TaggedLogging.new(logger)
  end

  class BookingMethod
    attr_accessor :template # required
    attr_accessor :auto_book # optional; valid values: yes, no [default]
    attr_accessor :label # optional; valid values: yes, no [default]
    attr_accessor :label_type # valid values: A5, LABEL [default]
    attr_accessor :error_mail # optional

    def initialize(params = {})
      self.auto_book = true
      self.label = true
      self.label_type = "LABEL"

      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def auto_book_value
      auto_book ? "yes" : "no"
    end

    def label_value
      label ? "yes" : "no"
    end
  end

  class Consignor
    attr_accessor :id
    attr_accessor :name
    attr_accessor :address_1
    attr_accessor :address_2
    attr_accessor :post_code
    attr_accessor :city
    attr_accessor :country_code
    attr_accessor :phone_number
    attr_accessor :contact_person

    def initialize(params = {})
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def contact_person_value
      @contact_person || "-"
    end

    def country_code=(value)
      @country_code = value.present? ? value.upcase : nil
    end
  end

  class Consignee
    attr_accessor :id
    attr_accessor :name
    attr_accessor :address_1
    attr_accessor :address_2
    attr_accessor :post_code
    attr_accessor :city
    attr_accessor :country_code
    attr_accessor :contact_person
    attr_accessor :phone_number

    def initialize(params = {})
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def contact_person_value
      @contact_person || "-"
    end

    def country_code=(value)
      @country_code = value.present? ? value.upcase : nil
    end
  end

  class Delivery
    attr_accessor :name
    attr_accessor :address_1
    attr_accessor :address_2
    attr_accessor :post_code
    attr_accessor :city
    attr_accessor :country_code
    attr_accessor :phone_number
    attr_accessor :contact_person
    attr_accessor :instructions # optional
    attr_accessor :date

    def initialize(params = {})
      self.instructions = "Standard"

      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def id
      "NO_ID"
    end

    def contact_person_value
      @contact_person || "-"
    end

    def country_code=(value)
      @country_code = value.present? ? value.upcase : nil
    end

    def formatted_date
      date ? date.strftime(DATE_FORMAT) : nil
    end
  end

  class Pickup
    attr_accessor :date
    attr_accessor :earliest_time
    attr_accessor :latest_time
    attr_accessor :instructions
    attr_accessor :by_carrier

    def initialize(params = {})
      # Default
      self.earliest_time = "15:00"
      self.latest_time =  "16:00"
      self.instructions = "call before pickup"
      self.by_carrier = false

      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def formatted_date
      date ? date.strftime(DATE_FORMAT) : nil
    end

    def by_carrier_value
      by_carrier ? "yes" : "no"
    end
  end

  class TransporService
    attr_accessor :reliable_to_duty
    attr_accessor :delivery_type # valid values: DD, DA, DP, AD, AA, AP, PD, PA, PP, DT, TD, TT
    attr_accessor :value
    attr_accessor :currency
    attr_accessor :warning # valid values: yes [default], no

    def initialize(params = {})
      self.delivery_type = "DD"

      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def reliable_to_duty_value
      reliable_to_duty ? "yes" : "no"
    end
  end

  class GoodsItem
    attr_accessor :no_of_packages # required
    attr_accessor :length, :width, :height # required; dimensions are in centimeters
    attr_accessor :weight # required; total of goods_item; in kilograms
    attr_accessor :package_code # valid values: 20FB, 20FC, 20FL, 20GP, 20HC, 20IS, 20NOR, 20OT, 20RF, 20RH, 20TK, 20VT, 40FB, 40FC, 40FL, 40GP, 40HC, 40IS, 40NOR, 40OT, 40RF, 40RH, 40TK, 40VT, 45HC, BAG, BLU, BAL, BLC, BSK, BOT, BOX, BBK, BBG, VR, BND, CTN, CAS, CAP, COI, CNT, CRD, CRT, CYL, DRM, ENV, KEG, OCT, PKG, PAI, PLT, PAP, PPT, PLP, PCE, REL, RLL, SA, SET, SHT, SKD, SPL, TUB, UNT, WCA, WCR
    attr_accessor :description # required
    attr_accessor :shipping_mark

    def initialize(params = {})
      self.no_of_packages = 1
      self.package_code = "PKG"

      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def formatted_total_weight
      total_weight.round(3)
    end

    def total_weight
      no_of_packages * BigDecimal(weight, Float::DIG)
    end

    def volume_in_cm3
      if length && width && height
        no_of_packages * length * width * height
      else
        nil
      end
    end

    def volume_in_m3
      if v = volume_in_cm3
        (v * 1e-6).round
      else
        nil
      end
    end
  end
end

# API documentation for GLS Web API can be found at http://api.gls.dk/ws

class GLSShipmentHTTPRequestBody
  attr_accessor :shipment
  attr_accessor :parcelshop_id
  attr_accessor :test

  delegate :sender, to: :shipment
  delegate :recipient, to: :shipment
  delegate :carrier_product, to: :shipment
  delegate :carrier, to: :carrier_product

  def initialize(shipment)
    self.shipment = shipment
  end

  def shop_delivery_value
    parcelshop_id if carrier_product.gls_deliver_to_parcelshop?
  end

  def notification_email_value
    recipient.email unless carrier_product.gls_deliver_to_parcelshop?
  end

  def private_delivery_value
    "Y" if private_delivery?
  end

  def private_delivery?
    carrier_product.gls_is_private_service?
  end

  def deposit_value
    shipment.delivery_instructions.presence
  end

  def shop_return_value
    shop_return?
  end

  def pickup?
    shop_return?
  end

  def shop_return?
    shipment.return_label || carrier_product.gls_shop_return_product?
  end

  def parcels
    shipment.package_dimensions.dimensions.map do |dimension|
      Parcel.new(weight: dimension.weight, comment: shipment.remarks)
    end
  end

  def pickup_details
    sender
  end

  def formatted_shipping_date
    shipment.shipping_date.strftime("%Y%m%d")
  end

  def reference_value
    shipment.reference || ""
  end

  def to_json
    to_builder.target!
  end

  def to_builder
    Jbuilder.new do |json|
      json.UserName credentials.username
      json.Password credentials.password
      json.Customerid credentials.customer_id
      json.Contactid credentials.contact_id

      json.ShipmentDate formatted_shipping_date
      json.Reference "CF-#{shipment.unique_shipment_id}"

      json.System "CargoFlux"

      json.Addresses do
        json.AlternativeShipper do
          json.Name1 sender.company_name
          json.Name2 sender.address_line2
          json.Name3 sender.address_line3
          json.Street1 sender.address_line1
          json.CountryNum sender.country_number
          json.ZipCode sender.zip_code
          json.City sender.city
          json.Contact sender.attention
          json.Email sender.email
          json.Phone sender.phone_number
          json.Mobile sender.phone_number
        end

        json.Delivery do
          json.Name1 recipient.company_name
          json.Name2 recipient.address_line2
          json.Name3 recipient.address_line3
          json.Street1 recipient.address_line1
          json.CountryNum recipient.country_number
          json.ZipCode recipient.zip_code
          json.City recipient.city
          json.Contact recipient.attention
          json.Email recipient.email
          json.Phone recipient.phone_number
          json.Mobile recipient.phone_number
        end

        if pickup?
          json.Pickup do
            json.Name1 pickup_details.company_name
            json.Name2 pickup_details.address_line2
            json.Name3 pickup_details.address_line3
            json.Street1 pickup_details.address_line1
            json.CountryNum pickup_details.country_number
            json.ZipCode pickup_details.zip_code
            json.City pickup_details.city
            json.Contact pickup_details.attention
            json.Email pickup_details.email
            json.Phone pickup_details.phone_number
            json.Mobile pickup_details.phone_number
          end
        else
          json.Pickup nil
        end
      end

      json.Parcels parcels do |parcel|
        json.Weight parcel.weight
        json.Comment parcel.comment
        json.Reference reference_value
      end

      json.Services do
        json.ShopDelivery shop_delivery_value
        json.NotifcationEmail notification_email_value
        json.PrivateDelivery private_delivery_value
        json.Deposit deposit_value
        json.ShopReturn shop_return_value
      end
    end
  end

  private

  def credentials
    c = Credentials.build_from_carrier_product(carrier_product, test: test)

    override_carrier_credential = carrier.override_credentials_class.find_by(target: carrier, owner: shipment.customer)
    if override_carrier_credential
      c.username = override_carrier_credential.username if override_carrier_credential.username
      c.password = override_carrier_credential.password if override_carrier_credential.password
      c.customer_id = override_carrier_credential.customer_id if override_carrier_credential.customer_id
      c.contact_id = override_carrier_credential.contact_id if override_carrier_credential.contact_id
    end

    c
  end

  class Parcel
    attr_accessor :weight
    attr_accessor :comment

    def initialize(params = {})
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end if params
    end
  end

  class Credentials
    class << self
      def build_from_carrier_product(carrier_product, test:)
        key_prefix = test ? "test_" : ""

        new(
          username: carrier_product.get_credentials[:"#{key_prefix}username"],
          password: carrier_product.get_credentials[:"#{key_prefix}password"],
          customer_id: carrier_product.get_credentials[:"#{key_prefix}customer_id"],
          contact_id: carrier_product.get_credentials[:"#{key_prefix}contact_id"],
        )
      end
    end

    attr_accessor :username, :password, :customer_id, :contact_id

    def initialize(params = {})
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end
  end
end

class UnifaunShipmentHTTPRequestBody
  attr_accessor :shipment
  attr_accessor :test

  def initialize(shipment, test: nil)
    self.shipment = shipment
    self.test = test
  end

  def to_json(variant: :create_shipment)
    to_builder(variant: variant).target!
  end

  def to_builder(variant: :create_shipment)
    case variant
    when :create_shipment
      Jbuilder.new do |json|
        json.pdfConfig pdf_config
        json.shipment { render_shipment(json: json) }
      end
    when :store_shipment
      Jbuilder.new do |json|
        render_shipment(json: json)
      end
    end
  end

  def addons
    addons = []

    addons << ADDONS.fetch(:flex_delivery) if shipment.delivery_instructions.present?
    addons << ADDONS.fetch(:sms_notification) if shipment.recipient.phone_number.present?
    addons << ADDONS.fetch(:email_notification) if shipment.recipient.email.present?
    addons << ADDONS.fetch(:pickup_option) if shipment.parcelshop_id?

    addons
  end

  def pdf_config
    {
      "target4XOffset" => 0,
      "target2YOffset" => 0,
      "target2Media"   => "thermo-190",
      "target1YOffset" => 0,
      "target3YOffset" => 0,
      "target1Media"   => "laser-a4",
      "target4YOffset" => 0,
      "target4Media"   => nil,
      "target3XOffset" => 0,
      "target3Media"   => nil,
      "target1XOffset" => 0,
      "target2XOffset" => 0,
    }
  end

  private

  def render_shipment(json:)
    json.sender do
      render_party(shipment.sender, json: json)

      json.quickId 1
    end

    if (sender_partners = shipment.carrier_product.postnord_sender_partners) && sender_partners.size > 0
      json.senderPartners sender_partners do |sender_partner|
        json.id sender_partner[:id]
        json.custNo sender_partner[:customer_number]
      end
    end

    json.receiver do
      render_party(shipment.recipient, json: json)

      json.mobile shipment.recipient.phone_number
    end

    if shipment.parcelshop_id?
      json.agent do
        json.quickId shipment.parcelshop_id
      end
    end

    if shipment.carrier_product.postnord_pallet?
      json.parcels shipment.package_dimensions.dimensions do |package_dimension|
        json.weight package_dimension.weight
        json.copies 1
        json.valuePerParcel true
        json.reference shipment.reference
        json.contents shipment.description
        json.packageCode pallet_dimension_to_package_code(package_dimension)
      end
    else
      json.parcels shipment.package_dimensions.dimensions do |package_dimension|
        json.weight package_dimension.weight
        json.copies 1
        json.valuePerParcel false
        json.reference shipment.reference
        json.contents shipment.description
      end
    end

    json.service do
      json.id shipment.carrier_product.service
      json.addons addons do |addon|
        json.id addon.id
      end
    end

    json.reference shipment.reference
    json.senderReference shipment.reference
    json.test test
    json.freeText1 shipment.unique_shipment_id
    json.freeText2 shipment.delivery_instructions
    json.deliveryInstruction shipment.delivery_instructions
    json.orderNo shipment.unique_shipment_id
  end

  def render_party(party, json:)
    json.phone party.phone_number
    json.email party.email
    json.zipcode party.zip_code
    json.name party.company_name
    json.contact party.attention
    json.address1 party.address_line1
    json.address2 party.address_line2
    json.address3 party.address_line3
    json.country party.country_code.try(:upcase)
    json.state party.state_code.try(:upcase)
    json.city party.city
  end

  PALLET_SIZE_TO_IDENTIFIER = {
    [60,  40] => :quarter,
    [80,  60] => :half,
    [120, 80] => :whole,
  }

  PALLET_IDENTIFIER_TO_PACKAGE_CODE = {
    :quarter => "OA",
    :half    => "AF",
    :whole   => "PE",
    :unknown => "PE", # This could also have been set to OF=Specialpall but for now we'll do it like this.
  }

  def pallet_dimension_to_package_code(dimension)
    length, width = Integer(dimension.length), Integer(dimension.width)
    identifier = PALLET_SIZE_TO_IDENTIFIER[[length, width]] || PALLET_SIZE_TO_IDENTIFIER[[width, length]] || :unknown
    PALLET_IDENTIFIER_TO_PACKAGE_CODE.fetch(identifier)
  end

  Addon = Struct.new(:id)

  ADDONS = {
    :email_notification => Addon.new("NOTEMAIL"), # Email-advisering
    :sms_notification => Addon.new("NOTSMS"), # SMS-advisering
    :flex_delivery => Addon.new("DLVFLEX"), # Flexlevering
    :pickup_option => Addon.new("PUPOPT"), # Valgfrit afhentningssted
  }

  private_constant :ADDONS, :Addon
end

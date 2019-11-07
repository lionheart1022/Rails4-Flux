class DSVBookingMessage
  DSV_RECIPIENT_ID = "5790000110018"
  DSV_SENDER_ID = "cargoflux"

  attr_accessor :shipment
  attr_accessor :consignment_identifier
  attr_accessor :test_indicator

  alias_method :test_indicator?, :test_indicator

  delegate :sender, to: :shipment
  delegate :recipient, to: :shipment
  delegate :carrier_product, to: :shipment
  delegate :carrier, to: :carrier_product

  def initialize(shipment, consignment_identifier, test: true)
    self.shipment = shipment
    self.consignment_identifier = consignment_identifier
    self.test_indicator = test
  end

  def as_edifact
    builder = EdifactBuilder.new.tap do |b|
      b.add "UNB", unb_segment
      b.add "UNH", [message_reference, ["IFTMIN", "D", "10B", "UN"]]
      b.add "BGM", ["610", document_identifier, message_function_code]

      b.add "DTM", [["137", issued_at.strftime("%Y%m%d%H%M"), "203"]]
      b.add "DTM", [["234", collection_date.strftime("%Y%m%d"), "102"]]

      b.add "TSR", [nil, carrier_product.service, priority_code]

      b.add "FTX", ["CLR", nil, nil, pickup_instructions]

      b.add "CNT", [["7", shipment.package_dimensions.total_rounded_weight(3), "KGM"]]
      b.add "CNT", [["11", shipment.package_dimensions.number_of_packages, "PCE"]]
      b.add("CNT", [["19", shipment.number_of_pallets, "PLL"]]) if shipment.number_of_pallets?

      b.add "LOC", ["ZBO", [location_identifier, nil, "6"]]

      b.add "TOD", ["6", nil, incoterm_code]
      b.add "LOC", ["1", [nil, nil, nil, tod_location_name]]

      b.add "RFF", [["CU", consignment_identifier]]

      b.add "TDT", ["20", nil, transport_mode]

      b.add "NAD", ["CZ", [customer_number, nil, "87"], nil, [sender.company_name, nil, nil, nil, nil, "ZAO"], sender.address_line1, sender.city, nil, sender.zip_code, sender.country_code.try(:upcase)]
      b.add "NAD", ["CN", [customer_number, nil, "91"], nil, [recipient.company_name, nil, nil, nil, nil, "ZAO"], recipient.address_line1, recipient.city, nil, recipient.zip_code, recipient.country_code.try(:upcase)]
      b.add "NAD", ["PW", [customer_number, nil, "87"], nil, [despatch_party.company_name, nil, nil, nil, nil, "ZAO"], despatch_party.address_line1, despatch_party.city, nil, despatch_party.zip_code, despatch_party.country_code.try(:upcase)]

      shipment.package_dimensions.dimensions.each_with_index do |package_dimension, index|
        goods_item_number = index + 1

        b.add "GID", [goods_item_number, [1, "CLL"]] # For now we only support CLL = Kolli
        b.add "MEA", ["WT", "AAB", ["KGM", package_dimension.weight]]
        b.add "PCI", ["18"]
        b.add "GIN", ["AW", ean_sscc_code(package_index: index)]
      end

      b.add "UNT", [b.number_of_segments, message_reference]
      b.add "UNZ", [1, message_reference]
    end

    builder.as_string(separate_segments_with_newline: true)
  end

  def unb_segment
    segment =
      [
        ["UNOC", "4"],
        [DSV_SENDER_ID, "ZZ"],
        [DSV_RECIPIENT_ID, "14"],
        [prepared_at.strftime("%Y%m%d"), prepared_at.strftime("%H%M")],
        recipient_reference,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
      ]

    segment << "1" if test_indicator?

    segment
  end

  def prepared_at
    @prepared_at ||= Time.zone.now
  end

  def issued_at
    shipment.created_at
  end

  def collection_date
    shipment.shipping_date
  end

  def ean_sscc_code(package_index:)
    DSVPackage.find_by!(shipment: shipment, package_index: package_index).unique_identifier
  end

  def customer_number
    credentials[:customer_number].presence || raise("DSV customer number is missing")
  end

  def transport_mode
    "3" # Road transport
  end

  # Dynamically determine value from rule:
  #
  # > Afhentningsadresse routing
  # > Postcode 0 – 4999 = DKCPH
  # > Postcode 5000 – 9999 = DKHOR
  def location_identifier
    zip_code = String(despatch_party.zip_code).strip

    carrier_product.zip_code_to_dsv_location_identifier(zip_code)
  end

  def tod_location_name
    recipient.city
  end

  def despatch_party
    if shipment.pickup_relation
      shipment.pickup_relation.contact
    else
      sender
    end
  end

  def pickup_instructions
    if shipment.pickup_relation
      shipment.pickup_relation.description
    else
      consignment_identifier
    end
  end

  def incoterm_code
    "DDP" # TODO: This should be a new field on the shipment
  end

  def priority_code
    "3" # Normal speed
  end

  def recipient_reference
    consignment_identifier
  end

  def message_reference
    consignment_identifier
  end

  def document_identifier
    consignment_identifier
  end

  def message_function_code
    "9" # Original
  end

  private

  def credentials
    @credentials ||= shipment.carrier_product.get_credentials
  end
end

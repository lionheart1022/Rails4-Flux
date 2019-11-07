class KHTMessage
  TERMINAL_NR = "66"
  EDI_TYPE_INSERT = "INSERT"
  NO = "NEJ"
  EUR_PALLET_DIMENSIONS = [120, 80]

  attr_reader :shipment
  attr_reader :waybill_number
  attr_reader :track_trace_number
  attr_reader :credentials
  attr_reader :test_booking

  def initialize(shipment:, waybill_number:, track_trace_number:, credentials:, test_booking: true)
    @shipment = shipment
    @waybill_number = waybill_number
    @track_trace_number = track_trace_number
    @credentials = credentials
    @test_booking = test_booking
  end

  def to_xml
    to_builder.to_xml
  end

  def booking_creator
    "66"
  end

  def sender_id
    credentials.sender_id
  end

  def customer_number
    credentials.customer_number
  end

  def production_booking?
    !test_booking
  end

  def terminal_nr
    TERMINAL_NR
  end

  def booking_type
    # TODO: "Står i beskrivelsen, aftal med Dan hvad de vil have P, D eller PD"
    # > Er bookingen en Afhentning til terminal (Reastante transport)(P). Levering fra en terminal (private indlevering på terminal) (D). eller fuld standart transport(PD)
    "PD"
  end

  def edi_type
    EDI_TYPE_INSERT
  end

  def collection_date
    if shipment.pickup_relation
      shipment.pickup_relation.pickup_date
    else
      shipment.shipping_date
    end
  end

  def formatted_delivery_date
    shipment.shipping_date.strftime("%Y%m%d")
  end

  def formatted_collection_time
    if shipment.pickup_relation
      time_match = /(?<hours>\d{2}):(?<minutes>\d{2})/.match(shipment.pickup_relation.from_time)
      if time_match
        "#{time_match[:hours]}#{time_match[:minutes]}"
      end
    else
      nil
    end
  end

  def formatted_collection_date
    collection_date.strftime("%Y%m%d")
  end

  def formatted_total_weight
    shipment.package_dimensions.total_rounded_weight(0).to_s
  end

  def formatted_customer_number
    sprintf("%08d", Integer(customer_number))
  end

  def to_builder
    Nokogiri::XML::Builder.new(encoding: "Windows-1252") do |xml|
      xml.Bookings do
        xml.DocHeader do
          xml.SenderID sender_id
        end

        xml.Booking do
          xml.FBHeader { build_fb_header(xml) }
          xml.SenderAddress { build_sender_address(xml) }
          xml.RecipientAddress { build_recipient_address(xml) }
          xml.General { build_general(xml) }
          xml.Specialities { build_specialities(xml) }

          shipment.package_dimensions.dimensions.each_with_index do |package_dimension, index|
            goods_line_number = index + 1

            xml.DescriptionOfGoods do
              xml.LineNr goods_line_number
              xml.BarCode ""
              xml.ColliType package_dimension_to_colli_type(package_dimension)
              xml.GoodsDescription shipment.description.to_s
              xml.Weight package_dimension.weight.round.to_s
              xml.Volume "0"
              xml.LDM "0"
              xml.ADR_UN nil
              xml.ParcelReference nil
              xml.Height package_dimension.height.to_s
              xml.Width package_dimension.width.to_s
              xml.Length package_dimension.length.to_s
              xml.Colli "1"
            end
          end
        end
      end
    end
  end

  private

  def build_fb_header(xml)
    xml.FBNR waybill_number
    xml.BookingCreator booking_creator
    xml.KnNr formatted_customer_number
    xml.TrgKnNr ""
    xml.TrackAndTraceNr track_trace_number
    xml.TerminalNr terminal_nr
    xml.Reference shipment.reference
    xml.Reference2 "CF_#{shipment.unique_shipment_id}"
    xml.BookingType booking_type
    xml.ProduktionTest production_booking? ? "P" : "T"
    xml.EdiType edi_type
  end

  def build_sender_address(xml)
    xml.SenderKnNr "0"
    xml.SenderName shipment.sender.company_name
    xml.SenderAddressLine1 shipment.sender.address_line1
    xml.SenderAddressLine2 shipment.sender.address_line2
    xml.SenderAddressLine3 shipment.sender.address_line3
    xml.SenderZip shipment.sender.zip_code
    xml.SenderCity shipment.sender.city
    xml.SenderCountry shipment.sender.country_code
    xml.SenderMail shipment.sender.email
    xml.SenderPhoneNo shipment.sender.phone_number
  end

  def build_recipient_address(xml)
    xml.RecipientKnNr "0"
    xml.RecipientName shipment.recipient.company_name
    xml.RecipientAddressLine1 shipment.recipient.address_line1
    xml.RecipientAddressLine2 shipment.recipient.address_line2
    xml.RecipientAddressLine3 shipment.recipient.address_line3
    xml.RecipientZip shipment.recipient.zip_code
    xml.RecipientCity shipment.recipient.city
    xml.RecipientCountry shipment.recipient.country_code
    xml.RecipientMail shipment.recipient.email
    xml.RecipientPhoneNo shipment.recipient.phone_number
  end

  def build_general(xml)
    xml.Notes shipment.remarks
    xml.DeliveryDate formatted_delivery_date
    xml.DeliveryTime nil
    xml.TotalWeight formatted_total_weight
    xml.TotalVolume "0"
    xml.TotalColli "0"
    xml.TotalLDM "0"
    xml.Franco "FRANKO"
  end

  def build_specialities(xml)
    xml.CODAmount "0"
    xml.CollectionDate formatted_collection_date
    xml.CollectionTime formatted_collection_time
    xml.DangerousGoods NO
    xml.CraneTruck NO
    xml.CarPackage NO
    xml.ExchangePallets NO
  end

  def package_dimension_to_colli_type(package_dimension)
    case
    when [package_dimension.width, package_dimension.length] == EUR_PALLET_DIMENSIONS
      "EUR"
    when [package_dimension.length, package_dimension.width] == EUR_PALLET_DIMENSIONS
      "EUR"
    else
      "1/1"
    end
  end
end

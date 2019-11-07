require "test_helper"

class KHTMessageTest < ActiveSupport::TestCase
  test "generates message" do
    credentials = OpenStruct.new(
      sender_id: "11112222-3333-4444-5555-666677778888",
      customer_number: "43230123",
    )

    carrier_product = CarrierProduct.new
    shipment = Shipment.new(
      carrier_product: carrier_product,
      shipping_date: Date.today,
      unique_shipment_id: "1-1-1",
      reference: "6327",
      remarks: "SKAL LEVERES INDEN KL. 14.00",
      number_of_packages: 1,
      package_dimensions: PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
        builder.add_package(length: 120, width: 80, height: 150, weight: BigDecimal("600"))
      end
    )
    shipment.build_sender(company_name: "VVS TRADING A/S", address_line2: "ELLEGÅRDVEJ 30", city: "SØNDERBORG", zip_code: "6400", country_code: "DK")
    shipment.build_recipient(company_name: "JEM & FIX SVENDBORG", address_line2: "VESTERGADE 100", city: "SVENDBORG", zip_code: "5700", country_code: "DK")

    message = KHTMessage.new(
      shipment: shipment,
      waybill_number: "02367555",
      track_trace_number: "023675551007783800",
      credentials: credentials,
    )
    message_as_xml = message.to_xml

    if ENV["OUTPUT_MESSAGE"] == "true"
      puts "*" * 80
      puts message_as_xml
      puts "*" * 80
    end

    assert message_as_xml
  end
end

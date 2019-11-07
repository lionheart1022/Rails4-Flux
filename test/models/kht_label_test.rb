require "test_helper"

class KHTLabelTest < ActiveSupport::TestCase
  test "generates label" do
    carrier_product = CarrierProduct.new

    shipment = Shipment.new(
      carrier_product: carrier_product,
      created_at: Time.zone.now,
      shipping_date: Date.today,
      awb: "023675551007783800",
      unique_shipment_id: "1-1-1",
      reference: "6327",
      remarks: "SKAL LEVERES INDEN KL. 14.00",
      number_of_packages: 1,
    )
    shipment.build_sender(company_name: "VVS TRADING A/S", address_line2: "ELLEGÅRDVEJ 30", city: "SØNDERBORG", zip_code: "6400", country_code: "DK")
    shipment.build_recipient(company_name: "JEM & FIX SVENDBORG", address_line2: "VESTERGADE 100", city: "SVENDBORG", zip_code: "5700", country_code: "DK")
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
      builder.add_package(length: 120, width: 80, height: 150, weight: BigDecimal("600"))
    end

    package_barcode_number_mapping = {
      0 => "#{shipment.awb}0001",
      1 => "#{shipment.awb}0002",
    }

    label = KHTLabel.build(
      shipment: shipment,
      package_barcode_number_mapping: package_barcode_number_mapping,
      track_trace_number: shipment.awb,
      waybill_number: shipment.awb[0..7],
      customer_number: "43230123",
      terminal_number: "66",
    )
    label.save_as(Rails.root.join("kht-test-label.pdf"))
  end
end if ENV["KHT_TEST_LABEL"] == "1"

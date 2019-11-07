require "test_helper"

class DSVLabelTest < ActiveSupport::TestCase
  test "generates label" do
    carrier_product = CarrierProduct.new

    shipment = Shipment.new(
      created_at: Time.zone.now,
      shipping_date: Date.today,
      carrier_product: carrier_product,
      awb: "CF1X1X1",
      unique_shipment_id: "1-1-1",
    )
    shipment.build_sender(
      company_name: "Cembrit Logistics A/S",
      address_line1: "Sohngårdsholmsvej 2",
      city: "Aalborg",
      zip_code: "9100",
      country_code: "dk",
    )
    shipment.build_recipient(
      company_name: "STARK Ishøj",
      address_line1: "Industribuen 15",
      address_line2: "Port 12",
      city: "Ishøj",
      zip_code: "2635",
      country_code: "dk",
    )
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: shipment.carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: BigDecimal("8.61"))
      builder.add_package(length: 30, width: 50, height: 80, weight: BigDecimal("13.7"))
    end

    package_sscc_mapping = {
      0 => "123",
      1 => "456",
    }

    label = DSVLabel.build(shipment: shipment, package_sscc_mapping: package_sscc_mapping)
    label.save_as(Rails.root.join("dsv-test-label.pdf"))
  end
end if ENV["DSV_TEST_LABEL"] == "1"

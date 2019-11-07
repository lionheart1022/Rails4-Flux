require "test_helper"

class UPSRequestInspectorTest < ActiveSupport::TestCase
  test "request body is read" do
    shipment = Shipment.new
    shipment.delivery_instructions = "Here's some instructions!"
    shipment.carrier_product = UPSSaverCarrierProduct.new
    shipment.build_sender(
      company_name: "Cargoflux ApS",
      attention: "Fragtmand",
      address_line1: "Njalsgade 17A",
      address_line2: "",
      address_line3: "",
      zip_code: "2300",
      city: "Copenahgen",
      country_code: "DK",
      state_code: "",
      phone_number: "",
      email: "",
    )
    shipment.build_recipient(
      company_name: "Legoland",
      attention: "Legomand",
      address_line1: "Nordmarksvej 9",
      address_line2: nil,
      address_line3: nil,
      zip_code: "7190",
      city: "Billund",
      country_name: "Denmark",
      country_code: "dk",
      email: "legoland@example.com",
      phone_number: nil,
    )
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: shipment.carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: 1)
      builder.add_package(length: 30, width: 40, height: 50, weight: 2)
    end

    request_body = UPSRequestInspector.new(shipment).confirm_request_body

    assert request_body.present?
  end
end

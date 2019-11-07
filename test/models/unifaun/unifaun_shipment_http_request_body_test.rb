require "test_helper"

class UnifaunShipmentHttpRequestBodyTest < ActiveSupport::TestCase
  test "#to_json with groupage product" do
    shipment = Shipment.new
    shipment.delivery_instructions = "Here's some instructions!"
    shipment.carrier_product = UnifaunGroupageCarrierProduct.new
    shipment.build_sender
    shipment.build_recipient(phone_number: "+4588888888", email: "recipient@example.com")
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: shipment.carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: 1)
      builder.add_package(length: 30, width: 40, height: 50, weight: 2)
    end

    body = UnifaunShipmentHTTPRequestBody.new(shipment)
    json = JSON.parse(body.to_json)

    assert json["pdfConfig"].present?
    assert json["shipment"].present?
    assert_equal shipment.carrier_product.service, json["shipment"]["service"]["id"]
    assert_equal 2, json["shipment"]["parcels"].count
    refute json["shipment"]["parcels"].first.key?("packageCode")
  end

  test "#to_json with pallet product" do
    shipment = Shipment.new
    shipment.delivery_instructions = "Here's some instructions!"
    shipment.carrier_product = UnifaunPalletCarrierProduct.new
    shipment.build_sender
    shipment.build_recipient(phone_number: "+4588888888", email: "recipient@example.com")
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: shipment.carrier_product) do |builder|
      builder.add_package(length: 60, width: 40, height: 100, weight: 100) # Quarter-pallet
      builder.add_package(length: 80, width: 60, height: 50, weight: 200) # Half-pallet
      builder.add_package(length: 120, width: 80, height: 150, weight: 300)
      builder.add_package(length: 125, width: 80, height: 150, weight: 300)
    end

    body = UnifaunShipmentHTTPRequestBody.new(shipment)
    json = JSON.parse(body.to_json)

    assert json["pdfConfig"].present?
    assert json["shipment"].present?
    assert_equal shipment.carrier_product.service, json["shipment"]["service"]["id"]
    assert_equal 4, json["shipment"]["parcels"].count
    assert_equal "OA", json["shipment"]["parcels"][0]["packageCode"]
    assert_equal "AF", json["shipment"]["parcels"][1]["packageCode"]
    assert_equal "PE", json["shipment"]["parcels"][2]["packageCode"]
    assert_equal "PE", json["shipment"]["parcels"][3]["packageCode"]
  end
end

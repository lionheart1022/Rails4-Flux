require "test_helper"

class UnifaunShipmentHttpRequestTest < ActiveSupport::TestCase
  class CustomPalletCarrierProduct < UnifaunGenericCarrierProduct
    def postnord_pallet?
      true
    end

    def service
      "P52DK"
    end
  end

  test "perform_store_shipment_request! with groupage product" do
    carrier_product = UnifaunGroupageCarrierProduct.create!(name: "PostNord DK Groupage")
    carrier_product.set_credentials(credentials: { id: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_ID"), secret: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_SECRET") })

    shipment = Shipment.new
    shipment.carrier_product = carrier_product
    shipment.build_sender(
      company_name: "CargoFlux",
      attention: nil,
      address_line1: "Njalsgade 23",
      address_line2: nil,
      address_line3: nil,
      zip_code: "2300",
      city: "København S",
      country_name: "Denmark",
      country_code: "dk",
      email: "cargoflux@example.com",
      phone_number: nil,
    )
    shipment.build_recipient(
      company_name: "Shape",
      attention: "Bacon",
      address_line1: "Njalsgade 17A",
      address_line2: nil,
      address_line3: nil,
      zip_code: "2300",
      city: "København S",
      country_name: "Denmark",
      country_code: "dk",
      email: "shape@example.com",
      phone_number: nil,
    )
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: 1)
      builder.add_package(length: 30, width: 40, height: 50, weight: 2)
    end

    http_request = UnifaunShipmentHTTPRequest.new(shipment)
    response = http_request.perform_store_shipment_request!
    json = JSON.parse(response.body)

    assert_equal 201, response.status
    assert_equal carrier_product.service, json["serviceId"]
    assert_equal shipment.package_dimensions.dimensions.count, json["parcelCount"]
    assert_equal "READY", json["status"]
  end

  test "perform_store_shipment_request! with groupage product with explicit agent" do
    carrier_product = UnifaunGroupageCarrierProduct.create!(name: "PostNord DK Groupage")
    carrier_product.set_credentials(credentials: { id: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_ID"), secret: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_SECRET") })

    shipment = Shipment.new
    shipment.parcelshop_id = "2307" # Agent no. of Posthus Kvickly, Englandsvej 28, 2300 København S
    shipment.carrier_product = carrier_product
    shipment.build_sender(
      company_name: "CargoFlux",
      attention: nil,
      address_line1: "Njalsgade 23",
      address_line2: nil,
      address_line3: nil,
      zip_code: "2300",
      city: "København S",
      country_name: "Denmark",
      country_code: "dk",
      email: "cargoflux@example.com",
      phone_number: nil,
    )
    shipment.build_recipient(
      company_name: "Shape",
      attention: "Bacon",
      address_line1: "Njalsgade 17A",
      address_line2: nil,
      address_line3: nil,
      zip_code: "2300",
      city: "København S",
      country_name: "Denmark",
      country_code: "dk",
      email: "shape@example.com",
      phone_number: nil,
    )
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: 1)
      builder.add_package(length: 30, width: 40, height: 50, weight: 2)
    end

    http_request = UnifaunShipmentHTTPRequest.new(shipment)
    response = http_request.perform_store_shipment_request!
    json = JSON.parse(response.body)

    assert_equal 201, response.status
    assert_equal carrier_product.service, json["serviceId"]
    assert_equal shipment.package_dimensions.dimensions.count, json["parcelCount"]
    assert_equal "READY", json["status"]
  end

  test "perform_store_shipment_request! with pallet product" do
    carrier_product = CustomPalletCarrierProduct.create!(name: "PostNord DK Pallet")
    carrier_product.set_credentials(credentials: { id: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_ID"), secret: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_SECRET") })

    shipment = Shipment.new
    shipment.carrier_product = carrier_product
    shipment.build_sender(
      company_name: "CargoFlux",
      attention: nil,
      address_line1: "Njalsgade 23",
      address_line2: nil,
      address_line3: nil,
      zip_code: "2300",
      city: "København S",
      country_name: "Denmark",
      country_code: "dk",
      email: "cargoflux@example.com",
      phone_number: nil,
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
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
      builder.add_package(length: 60, width: 40, height: 100, weight: 100) # Quarter-pallet
      builder.add_package(length: 80, width: 60, height: 50, weight: 200) # Half-pallet
      builder.add_package(length: 120, width: 80, height: 150, weight: 300)
      builder.add_package(length: 120, width: 80, height: 150, weight: 300)
      builder.add_package(length: 125, width: 80, height: 150, weight: 300)
    end

    http_request = UnifaunShipmentHTTPRequest.new(shipment)
    response = http_request.perform_store_shipment_request!
    json = JSON.parse(response.body)

    assert_equal 201, response.status
    assert_equal carrier_product.service, json["serviceId"]
    assert_equal shipment.package_dimensions.dimensions.count, json["parcelCount"]
    assert_equal "READY", json["status"]
  end

  test "perform_store_shipment_request! with pallet product (Norway)" do
    carrier_product = UnifaunPalletNorwayCarrierProduct.create!(name: "PostNord NO Pallet")
    carrier_product.set_credentials(credentials: {
      id: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_ID"),
      secret: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_SECRET"),
      customer_number: ENV.fetch("UNIFAUN_TEST_CUSTOMER_NUMBER"),
    })

    shipment = Shipment.new
    shipment.carrier_product = carrier_product
    shipment.build_sender(
      company_name: "Oslo Opera House",
      attention: nil,
      address_line1: "Kirsten Flagstads Plass 1",
      address_line2: nil,
      address_line3: nil,
      zip_code: "0150",
      city: "Oslo",
      country_name: "Norway",
      country_code: "no",
      email: "sender@example.com",
      phone_number: nil,
    )
    shipment.build_recipient(
      company_name: "Bjølsen Studenthus",
      attention: "Smart Guy",
      address_line1: "Moldegata 29",
      address_line2: nil,
      address_line3: nil,
      zip_code: "0468",
      city: "Oslo",
      country_name: "Norway",
      country_code: "no",
      email: "recipient@example.com",
      phone_number: nil,
    )
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
      builder.add_package(length: 60, width: 40, height: 100, weight: 100) # Quarter-pallet
      builder.add_package(length: 80, width: 60, height: 50, weight: 200) # Half-pallet
      builder.add_package(length: 120, width: 80, height: 150, weight: 300)
      builder.add_package(length: 120, width: 80, height: 150, weight: 300)
      builder.add_package(length: 125, width: 80, height: 150, weight: 300)
    end

    http_request = UnifaunShipmentHTTPRequest.new(shipment)
    response = http_request.perform_store_shipment_request!
    json = JSON.parse(response.body)

    assert_equal 201, response.status
    assert_equal carrier_product.service, json["serviceId"]
    assert_equal shipment.package_dimensions.dimensions.count, json["parcelCount"]
    assert_equal "READY", json["status"]
  end

  test "perform_store_shipment_request! with Norway Groupage product" do
    carrier_product = UnifaunGroupageNorwayCarrierProduct.create!(name: "PostNord NO Groupage")
    carrier_product.set_credentials(credentials: {
      id: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_ID"),
      secret: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_SECRET"),
      customer_number: ENV.fetch("UNIFAUN_TEST_CUSTOMER_NUMBER"),
    })

    shipment = Shipment.new
    shipment.carrier_product = carrier_product
    shipment.build_sender(
      company_name: "Oslo Opera House",
      attention: nil,
      address_line1: "Kirsten Flagstads Plass 1",
      address_line2: nil,
      address_line3: nil,
      zip_code: "0150",
      city: "Oslo",
      country_name: "Norway",
      country_code: "no",
      email: "sender@example.com",
      phone_number: nil,
    )
    shipment.build_recipient(
      company_name: "Bjølsen Studenthus",
      attention: "Smart Guy",
      address_line1: "Moldegata 29",
      address_line2: nil,
      address_line3: nil,
      zip_code: "0468",
      city: "Oslo",
      country_name: "Norway",
      country_code: "no",
      email: "recipient@example.com",
      phone_number: nil,
    )
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
      builder.add_package(length: 10, width: 10, height: 10, weight: 1)
    end

    http_request = UnifaunShipmentHTTPRequest.new(shipment)
    response = http_request.perform_store_shipment_request!
    json = JSON.parse(response.body)

    assert_equal 201, response.status
    assert_equal carrier_product.service, json["serviceId"]
    assert_equal shipment.package_dimensions.dimensions.count, json["parcelCount"]
    assert_equal "READY", json["status"]
  end

  test "book_shipment! with groupage product" do
    carrier_product = UnifaunGroupageCarrierProduct.create!(name: "PostNord DK Groupage")
    carrier_product.set_credentials(credentials: { id: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_ID"), secret: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_SECRET") })

    shipment = Shipment.new
    shipment.carrier_product = carrier_product
    shipment.build_sender(
      company_name: "CargoFlux",
      attention: nil,
      address_line1: "Njalsgade 23",
      address_line2: nil,
      address_line3: nil,
      zip_code: "2300",
      city: "København S",
      country_name: "Denmark",
      country_code: "dk",
      email: "cargoflux@example.com",
      phone_number: nil,
    )
    shipment.build_recipient(
      company_name: "Shape",
      attention: "Bacon",
      address_line1: "Njalsgade 17A",
      address_line2: nil,
      address_line3: nil,
      zip_code: "2300",
      city: "København S",
      country_name: "Denmark",
      country_code: "dk",
      email: "shape@example.com",
      phone_number: nil,
    )
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: 1)
      builder.add_package(length: 30, width: 40, height: 50, weight: 2)
    end

    http_request = UnifaunShipmentHTTPRequest.new(shipment)
    response = http_request.book_shipment!

    assert response.awb_no.present?
    assert response.pdf_url.present?

    response.generate_temporary_awb_pdf_file do |awb_pdf_path|
      assert awb_pdf_path.present?
    end
  end

  test "book_shipment! without credentials" do
    carrier_product = UnifaunGroupageCarrierProduct.create!(name: "PostNord DK Groupage")
    carrier_product.set_credentials(credentials: {})

    shipment = Shipment.new
    shipment.carrier_product = carrier_product
    shipment.build_sender(
      company_name: "CargoFlux",
      attention: nil,
      address_line1: "Njalsgade 23",
      address_line2: nil,
      address_line3: nil,
      zip_code: "2300",
      city: "København S",
      country_name: "Denmark",
      country_code: "dk",
      email: "cargoflux@example.com",
      phone_number: nil,
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
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: 1)
      builder.add_package(length: 30, width: 40, height: 50, weight: 2)
    end

    http_request = UnifaunShipmentHTTPRequest.new(shipment)

    assert_raises(UnifaunShipmentHTTPResponse::UnauthorizedError) do
      http_request.book_shipment!
    end
  end

  test "book_shipment! with missing data" do
    carrier_product = UnifaunGroupageCarrierProduct.create!(name: "PostNord DK Groupage")
    carrier_product.set_credentials(credentials: { id: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_ID"), secret: ENV.fetch("UNIFAUN_TEST_CREDENTIALS_SECRET") })

    shipment = Shipment.new
    shipment.carrier_product = carrier_product
    shipment.build_sender(
      company_name: "CargoFlux",
      attention: nil,
      address_line1: "Njalsgade 23",
      address_line2: nil,
      address_line3: nil,
      zip_code: "2300",
      city: "København S",
      country_name: "Denmark",
      country_code: "dk",
      email: "cargoflux@example.com",
      phone_number: nil,
    )
    shipment.build_recipient(
      company_name: "Legoland",
      attention: "Legomand",
      address_line1: nil,
      address_line2: nil,
      address_line3: nil,
      zip_code: "xxxx",
      city: "Billund",
      country_name: "Denmark",
      country_code: "dk",
      email: "legoland@example.com",
      phone_number: nil,
    )
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: 1)
      builder.add_package(length: 30, width: 40, height: 50, weight: 2)
    end

    http_request = UnifaunShipmentHTTPRequest.new(shipment)
    e = assert_raises(UnifaunShipmentHTTPResponse::ParameterError) { http_request.book_shipment! }

    assert e.as_shipment_errors.present?
  end
end if ENV["UNIFAUN_TEST"] == "1"

require "test_helper"

class UPSPrebookCheckTest < ActiveSupport::TestCase
  test "remote area surcharge" do
    company = Company.create!(name: "Company")
    carrier_product = UPSSaverCarrierProduct.create!(company: company, name: "UPS Saver")
    carrier_product.set_credentials(credentials: {
      company: ENV["UPS_CREDENTIALS_COMPANY"],
      account: ENV["UPS_CREDENTIALS_ACCOUNT"],
      password: ENV["UPS_CREDENTIALS_PASSWORD"],
      access_token: ENV["UPS_CREDENTIALS_ACCESS_TOKEN"],
    })

    shipment = Shipment.new(carrier_product: carrier_product, shipping_date: Date.today)
    shipment.build_sender(
      company_name: "Cargoflux ApS",
      attention: "",
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
      company_name: "Lakrids",
      attention: "",
      address_line1: "Glastorvet 1",
      address_line2: "",
      address_line3: "",
      zip_code: "3740",
      city: "Svaneke",
      country_code: "DK",
      state_code: "",
      phone_number: "",
      email: "",
    )
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: shipment.carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: 1)
      builder.add_package(length: 30, width: 40, height: 50, weight: 2)
    end

    result = UPSPrebookCheck.run(shipment)

    assert_equal 1, result.surcharges.count
    assert_equal "UPSSurcharges::AreaDelivery", result.surcharges[0].type
  end

  test "extended area surcharge" do
    company = Company.create!(name: "Company")
    carrier_product = UPSSaverCarrierProduct.create!(company: company, name: "UPS Saver")
    carrier_product.set_credentials(credentials: {
      company: ENV["UPS_CREDENTIALS_COMPANY"],
      account: ENV["UPS_CREDENTIALS_ACCOUNT"],
      password: ENV["UPS_CREDENTIALS_PASSWORD"],
      access_token: ENV["UPS_CREDENTIALS_ACCESS_TOKEN"],
    })

    shipment = Shipment.new(carrier_product: carrier_product, shipping_date: Date.today)
    shipment.build_sender(
      company_name: "Cargoflux ApS",
      attention: "",
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
      company_name: "DUNNO",
      attention: "",
      address_line1: "Slettervej 1",
      address_line2: "",
      address_line3: "",
      zip_code: "4944",
      city: "Fejø",
      country_code: "DK",
      state_code: "",
      phone_number: "",
      email: "",
    )
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: shipment.carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: 1)
      builder.add_package(length: 30, width: 40, height: 50, weight: 2)
    end

    result = UPSPrebookCheck.run(shipment)

    assert_equal 1, result.surcharges.count
    assert_equal "UPSSurcharges::AreaDelivery", result.surcharges[0].type
  end

  test "regular UPS Standard shipment" do
    company = Company.create!(name: "Company")
    carrier_product = UPSStandardCarrierProduct.create!(company: company, name: "UPS Standard")
    carrier_product.set_credentials(credentials: {
      company: ENV["UPS_CREDENTIALS_COMPANY"],
      account: ENV["UPS_CREDENTIALS_ACCOUNT"],
      password: ENV["UPS_CREDENTIALS_PASSWORD"],
      access_token: ENV["UPS_CREDENTIALS_ACCESS_TOKEN"],
    })

    shipment = Shipment.new(shipping_date: Date.today)
    shipment.carrier_product = carrier_product
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: shipment.carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: 1)
    end
    shipment.build_sender(
      company_name: "Cargoflux ApS",
      attention: "",
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
      company_name: "Candy & Balloon",
      attention: "Balloon Man",
      address_line1: "Berner Heerweg 173",
      address_line2: nil,
      address_line3: nil,
      zip_code: "22159",
      city: "Hamburg",
      country_name: "Germany",
      country_code: "de",
      email: "balloon@example.com",
      phone_number: nil,
    )

    result = UPSPrebookCheck.run(shipment)
    refute result.respond_to?(:surcharges), "No surcharges should be applied to this shipment"
  end

  test "ETA are correctly returned for Saver envelope and document" do
    company = Company.create!(name: "Company")
    carrier_products = [
      UPSSaverCarrierProduct.create!(company: company, name: "UPS Express Saver"),
      UPSSaverEnvelopeCarrierProduct.create!(company: company, name: "UPS Express Saver Envelope"),
      UPSSaverDocumentCarrierProduct.create!(company: company, name: "UPS Express Saver Document"),
    ]
    carrier_products.each do |carrier_product|
      carrier_product.set_credentials(credentials: {
        company: ENV["UPS_CREDENTIALS_COMPANY"],
        account: ENV["UPS_CREDENTIALS_ACCOUNT"],
        password: ENV["UPS_CREDENTIALS_PASSWORD"],
        access_token: ENV["UPS_CREDENTIALS_ACCESS_TOKEN"],
      })
    end
    shipment = Shipment.new(shipping_date: Date.today)
    shipment.build_sender(
      company_name: "Cargoflux ApS",
      attention: "",
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

    carrier_products.each do |carrier_product|
      shipment.carrier_product = carrier_product
      shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: shipment.carrier_product) do |builder|
        builder.add_package(length: 20, width: 20, height: 20, weight: 1)
      end

      result = UPSPrebookCheck.run(shipment)
      refute result.respond_to?(:surcharges)
      assert result.estimated_arrival_date
    end
  end

  test "ETA is correctly returned for UPS Standard (international)" do
    company = Company.create!(name: "Company")
    carrier_products = [
      UPSStandardCarrierProduct.create!(company: company, name: "UPS Standard"),
      UPSStandardSingleCarrierProduct.create!(company: company, name: "UPS Standard Single"),
    ]

    carrier_products.each do |carrier_product|
      carrier_product.set_credentials(credentials: {
        company: ENV["UPS_CREDENTIALS_COMPANY"],
        account: ENV["UPS_CREDENTIALS_ACCOUNT"],
        password: ENV["UPS_CREDENTIALS_PASSWORD"],
        access_token: ENV["UPS_CREDENTIALS_ACCESS_TOKEN"],
      })
    end

    shipment = Shipment.new(shipping_date: Date.today)
    shipment.build_sender(
      company_name: "Cargoflux ApS",
      attention: "",
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
      company_name: "Candy & Balloon",
      attention: "Balloon Man",
      address_line1: "Berner Heerweg 173",
      address_line2: nil,
      address_line3: nil,
      zip_code: "22159",
      city: "Hamburg",
      country_name: "Germany",
      country_code: "de",
      email: "balloon@example.com",
      phone_number: nil,
    )

    carrier_products.each do |carrier_product|
      shipment.carrier_product = carrier_product
      shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: shipment.carrier_product) do |builder|
        builder.add_package(length: 20, width: 20, height: 20, weight: 1)
      end

      result = UPSPrebookCheck.run(shipment)

      refute result.respond_to?(:surcharges)
      assert result.estimated_arrival_date
    end
  end
end if ENV.keys.grep(/^UPS_CREDENTIALS_/).any?

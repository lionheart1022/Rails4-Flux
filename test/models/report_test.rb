require "test_helper"

class ReportTest < ActiveSupport::TestCase
  test "generating excel report without detailed pricing" do
    company_a = Company.create!(name: "Company A", current_customer_id: 0, current_report_id: 0)
    customer_a = company_a.create_customer!(name: "Customer A") do |customer|
      customer.build_address(company_name: "Customer A", attention: "Test Person", address_line1: "Njalsgade 17A", zip_code: "2300", city: "København S", country_code: "dk", country_name: "Denmark")
    end

    carrier = Carrier.create!(company: company_a, name: "Custom Carrier")
    carrier_product = CarrierProduct.create_carrier_product(
      company_id: company_a.id,
      carrier_id: carrier.id,
      name: "Custom Carrier Product",
      custom_label: false,
      product_type: nil,
      product_code: nil,
      options: {},
    )

    shipments = [
      create_shipment(company: company_a, customer: customer_a, carrier_product: carrier_product),
      create_shipment(company: company_a, customer: customer_a, carrier_product: carrier_product),
      create_shipment(company: company_a, customer: customer_a, carrier_product: carrier_product),
    ]

    report = company_a.create_report!(bulk_insert_shipment_ids: shipments.map(&:id), with_detailed_pricing: false)

    assert_equal shipments.count, report.shipments.count
    refute report.download_url

    report.generate_excel_report_now!

    assert report.download_url

    if report.download_url
      file_uri = URI(report.download_url)
      creek = Creek::Book.new(file_uri.path)
      sheet = creek.sheets[0]

      assert_equal 4, sheet.rows.count

      delete_excel_report_file(report)
    end
  end

  test "generating excel report with detailed pricing" do
    company_a = Company.create!(name: "Company A", current_customer_id: 0, current_report_id: 0)
    customer_a = company_a.create_customer!(name: "Customer A") do |customer|
      customer.build_address(company_name: "Customer A", attention: "Test Person", address_line1: "Njalsgade 17A", zip_code: "2300", city: "København S", country_code: "dk", country_name: "Denmark")
    end

    carrier = Carrier.create!(company: company_a, name: "Custom Carrier")
    carrier_product = CarrierProduct.create_carrier_product(
      company_id: company_a.id,
      carrier_id: carrier.id,
      name: "Custom Carrier Product",
      custom_label: false,
      product_type: nil,
      product_code: nil,
      options: {},
    )

    shipments = [
      create_shipment(company: company_a, customer: customer_a, carrier_product: carrier_product),
      create_shipment(company: company_a, customer: customer_a, carrier_product: carrier_product),
      create_shipment(company: company_a, customer: customer_a, carrier_product: carrier_product),
    ]

    report = company_a.create_report!(bulk_insert_shipment_ids: shipments.map(&:id), with_detailed_pricing: true)

    assert_equal shipments.count, report.shipments.count
    refute report.download_url

    report.generate_excel_report_now!

    assert report.download_url

    if report.download_url
      file_uri = URI(report.download_url)
      creek = Creek::Book.new(file_uri.path)
      sheet = creek.sheets[0]

      assert_equal 13, sheet.rows.count

      delete_excel_report_file(report)
    end
  end

  test "generating Excel report later" do
    company_a = Company.create!(name: "Company A", current_customer_id: 0, current_report_id: 0)
    customer_a = company_a.create_customer!(name: "Customer A") do |customer|
      customer.build_address(company_name: "Customer A", attention: "Test Person", address_line1: "Njalsgade 17A", zip_code: "2300", city: "København S", country_code: "dk", country_name: "Denmark")
    end

    carrier = Carrier.create!(company: company_a, name: "Custom Carrier")
    carrier_product = CarrierProduct.create_carrier_product(
      company_id: company_a.id,
      carrier_id: carrier.id,
      name: "Custom Carrier Product",
      custom_label: false,
      product_type: nil,
      product_code: nil,
      options: {},
    )

    shipments = [
      create_shipment(company: company_a, customer: customer_a, carrier_product: carrier_product),
      create_shipment(company: company_a, customer: customer_a, carrier_product: carrier_product),
      create_shipment(company: company_a, customer: customer_a, carrier_product: carrier_product),
    ]

    report = company_a.create_report!(bulk_insert_shipment_ids: shipments.map(&:id), with_detailed_pricing: false)

    assert_equal shipments.count, report.shipments.count
    refute report.download_url

    report.generate_excel_report_later!

    report.reload
    assert report.download_url

    delete_excel_report_file(report)
  end

  private

  def create_shipment(company:, customer:, carrier_product:)
    scoped_shipment_id = customer.update_next_shipment_id
    created_at = Faker::Date.between(2.months.ago, Date.today)
    updated_at = created_at
    shipping_date = Faker::Date.between(created_at, Date.today)

    shipment = Shipment.create!(
      company_id: company.id,
      customer_id: customer.id,
      shipment_id: scoped_shipment_id,
      unique_shipment_id: "#{customer.id}-#{customer.customer_id}-#{scoped_shipment_id}",
      state: Shipment::States::CREATED,
      shipping_date: shipping_date,
      created_at: created_at,
      updated_at: updated_at,
      number_of_packages: 2,
      package_dimensions: PackageDimensions.new(dimensions: [PackageDimension.new(length: 10, width: 20, height: 30, weight: 7), PackageDimension.new(length: 10, width: 20, height: 30, weight: 5)]),
      dutiable: false,
      customs_amount: nil,
      customs_currency: nil,
      customs_code: nil,
      description: Faker::Commerce.product_name,
      carrier_product_id: carrier_product.id,
    )

    shipment.sender = customer.address.copy_as_sender
    shipment.sender.save!

    shipment.create_recipient!(
      company_name: Faker::Company.name,
      attention: Faker::Name.name,
      address_line1: Faker::Address.street_address,
      zip_code: "2300",
      city: "Copenhagen",
      country_code: "dk",
      phone_number: nil,
      email: nil,
    )

    advanced_price = AdvancedPrice.create!(
      shipment: shipment,
      cost_price_currency: "DKK",
      sales_price_currency: "DKK",
      seller: company,
      buyer: customer,
    )

    cost_price_amount = BigDecimal(Faker::Number.decimal(3, 2))
    profit = BigDecimal(Faker::Number.decimal(2, 2))

    AdvancedPriceLineItem.create!(
      advanced_price: advanced_price,
      description: "Fragt",
      cost_price_amount: cost_price_amount,
      sales_price_amount: (cost_price_amount + profit).round(2),
      price_type: "manual",
    )

    AdvancedPriceLineItem.create!(
      advanced_price: advanced_price,
      description: "Gebyr",
      cost_price_amount: 20,
      sales_price_amount: 50,
      price_type: "manual",
    )

    shipment
  end

  def delete_excel_report_file(report)
    match = report.download_url.match %r{file://(?<path>.+)}
    if match
      if match[:path].index(Rails.root.join("tmp").to_s) == 0
        File.unlink match[:path]
      else
        Rails.logger.error "Dangerous download URL (expected the file to be within tmp/, it is #{report.download_url.inspect})"
      end
    else
      Rails.logger.error "Unexpected download URL format (expected to start with file://, it is #{report.download_url.inspect})"
    end
  end
end

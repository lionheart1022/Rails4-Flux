require "test_helper"

module CalculatePriceChainForShipment
  class DirectTest < ActiveSupport::TestCase
    test "shipment being sold directly to customer" do
      company = Company.create!(name: "A Company")
      customer = Customer.create!(name: "A Customer", company: company)

      carrier_product = CarrierProduct.create!(name: "Custom Carrier Product", company: company)
      carrier_product.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product)
      customer_carrier_product.create_sales_price!(margin_percentage: "10")

      package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
        builder.add_package(length: 10, width: 10, height: 10, weight: 1)
      end

      prices = carrier_product.calculate_price_chain_for_shipment(
        company_id: company.id,
        customer_id: customer.id,
        sender_country_code: "DK",
        sender_zip_code: "2300",
        recipient_country_code: "DK",
        recipient_zip_code: "2700",
        package_dimensions: package_dimensions,
        distance_in_kilometers: nil,
        dangerous_goods: false,
      )

      assert prices.present?
      assert_equal 1, prices.length
      assert_equal 1, prices.first.advanced_price_line_items.length

      prices.first.advanced_price_line_items.first.tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("90.00"), line_item.cost_price_amount
        assert_equal BigDecimal("99.00"), line_item.sales_price_amount
      end
    end

    test "import-shipment being sold directly to customer" do
      company = Company.create!(name: "A Company")
      customer = Customer.create!(name: "A Customer", company: company)

      carrier_product = CarrierProduct.create!(name: "Custom Carrier Product", company: company, exchange_type_import: true)
      carrier_product.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_multi_zone_dk)

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product)
      customer_carrier_product.create_sales_price!(margin_percentage: "0")

      package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
        builder.add_package(length: 10, width: 10, height: 10, weight: 1)
      end

      prices = carrier_product.calculate_price_chain_for_shipment(
        company_id: company.id,
        customer_id: customer.id,
        sender_country_code: "DK",
        sender_zip_code: "2300",
        recipient_country_code: "DK",
        recipient_zip_code: "2700",
        package_dimensions: package_dimensions,
        distance_in_kilometers: nil,
        dangerous_goods: false,
      )

      assert prices.present?
      assert_equal 1, prices.length
      assert_equal 1, prices.first.advanced_price_line_items.length

      prices.first.advanced_price_line_items.first.tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("90.00"), line_item.cost_price_amount
        assert_equal BigDecimal("90.00"), line_item.sales_price_amount
      end
    end

    test "shipment being sold directly to customer with fuelcharge" do
      company = Company.create!(name: "A Company")
      customer = Customer.create!(name: "A Customer", company: company)

      carrier = Carrier.create!(name: "Custom Carrier")
      carrier_product = CarrierProduct.create!(name: "Custom Carrier Product", company: company, carrier: carrier)
      carrier_product.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      surcharge_on_carrier = carrier.find_fuel_charge
      surcharge_on_carrier.assign_attributes(calculation_method: "price_percentage", charge_value: "5", enabled: true)
      surcharge_on_carrier.save!

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product)
      customer_carrier_product.create_sales_price!(margin_percentage: "10")

      package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
        builder.add_package(length: 10, width: 10, height: 10, weight: 1)
      end

      prices = carrier_product.calculate_price_chain_for_shipment(
        company_id: company.id,
        customer_id: customer.id,
        sender_country_code: "DK",
        sender_zip_code: "2300",
        recipient_country_code: "DK",
        recipient_zip_code: "2700",
        package_dimensions: package_dimensions,
        distance_in_kilometers: nil,
        dangerous_goods: false,
      )

      assert prices.present?
      assert_equal 1, prices.length
      assert_equal 2, prices.first.advanced_price_line_items.length

      prices.first.advanced_price_line_items[0].tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("90.00"), line_item.cost_price_amount
        assert_equal BigDecimal("99.00"), line_item.sales_price_amount
      end

      prices.first.advanced_price_line_items[1].tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("4.50"), line_item.cost_price_amount
        assert_equal BigDecimal("4.95"), line_item.sales_price_amount

        assert line_item.parameters
        assert_equal BigDecimal("99.00"), line_item.parameters[:base]
        assert_equal BigDecimal("5.00"), line_item.parameters[:percentage]
      end
    end

    test "shipment being sold directly to customer with monthly fuelcharge" do
      company = Company.create!(name: "A Company")
      customer = Customer.create!(name: "A Customer", company: company)

      carrier = Carrier.create!(name: "Custom Carrier")
      carrier_product = CarrierProduct.create!(name: "Custom Carrier Product", company: company, carrier: carrier)
      carrier_product.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      surcharge_on_carrier = carrier.find_fuel_charge
      surcharge_on_carrier.assign_attributes(calculation_method: "price_percentage", charge_value: "5", enabled: true)
      surcharge_on_carrier.save!

      SurchargeWithExpiration.create!(
        owner: surcharge_on_carrier,
        surcharge: FuelSurcharge.new(description: "Fuel", calculation_method: "price_percentage", charge_value: "25"),
        valid_from: Time.zone.now.beginning_of_month,
        expires_on: Time.zone.now.end_of_month,
      )

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product)
      customer_carrier_product.create_sales_price!(margin_percentage: "10")

      package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
        builder.add_package(length: 10, width: 10, height: 10, weight: 1)
      end

      prices = carrier_product.calculate_price_chain_for_shipment(
        company_id: company.id,
        customer_id: customer.id,
        sender_country_code: "DK",
        sender_zip_code: "2300",
        recipient_country_code: "DK",
        recipient_zip_code: "2700",
        package_dimensions: package_dimensions,
        distance_in_kilometers: nil,
        dangerous_goods: false,
        shipping_date: Date.today,
      )

      assert prices.present?
      assert_equal 1, prices.length
      assert_equal 2, prices.first.advanced_price_line_items.length

      prices.first.advanced_price_line_items[0].tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("90.00"), line_item.cost_price_amount
        assert_equal BigDecimal("99.00"), line_item.sales_price_amount
      end

      prices.first.advanced_price_line_items[1].tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("22.50"), line_item.cost_price_amount
        assert_equal BigDecimal("24.75"), line_item.sales_price_amount

        assert line_item.parameters
        assert_equal BigDecimal("99.00"), line_item.parameters[:base]
        assert_equal BigDecimal("25.00"), line_item.parameters[:percentage]
      end
    end

    test "blank prices when sales price is inactive" do
      company = Company.create!(name: "A Company")
      customer = Customer.create!(name: "A Customer", company: company)

      carrier_product = CarrierProduct.create!(name: "Custom Carrier Product", company: company)
      carrier_product.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product)
      customer_carrier_product.create_sales_price!(margin_percentage: "") # <-- sales price is inactive

      package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
        builder.add_package(length: 10, width: 10, height: 10, weight: 1)
      end

      prices = carrier_product.calculate_price_chain_for_shipment(
        company_id: company.id,
        customer_id: customer.id,
        sender_country_code: "DK",
        sender_zip_code: "2300",
        recipient_country_code: "DK",
        recipient_zip_code: "2700",
        package_dimensions: package_dimensions,
        distance_in_kilometers: nil,
        dangerous_goods: false,
      )

      assert_equal [], prices
    end

    test "blank prices when weight is out of range" do
      company = Company.create!(name: "A Company")
      customer = Customer.create!(name: "A Customer", company: company)

      carrier_product = CarrierProduct.create!(name: "Custom Carrier Product", company: company)
      carrier_product.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product)
      customer_carrier_product.create_sales_price!(margin_percentage: "10")

      package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
        builder.add_package(length: 10, width: 10, height: 10, weight: 20) # <-- price document has a maximum of 1.5 kg
      end

      prices = carrier_product.calculate_price_chain_for_shipment(
        company_id: company.id,
        customer_id: customer.id,
        sender_country_code: "DK",
        sender_zip_code: "2300",
        recipient_country_code: "DK",
        recipient_zip_code: "2700",
        package_dimensions: package_dimensions,
        distance_in_kilometers: nil,
        dangerous_goods: false,
      )

      assert_equal [], prices
    end
  end
end

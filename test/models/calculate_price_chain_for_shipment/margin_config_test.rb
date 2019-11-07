require "test_helper"

module CalculatePriceChainForShipment
  class MarginConfigTest < ActiveSupport::TestCase
    test "shipment being sold directly to customer" do
      company = Company.create!(name: "A Company")
      customer = Customer.create!(name: "A Customer", company: company)

      carrier_product = CarrierProduct.create!(name: "Custom Carrier Product", company: company)
      carrier_product.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      margin_config = CarrierProductMarginConfigurations::PerZoneAndRange.new
      margin_config.generate_price_document_hash(carrier_product_price: carrier_product.carrier_product_price)
      margin_config.config_document = {
        "zones" => {
          "0" => [
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1" },
              "margin_amount" => "10",
            },
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1.5" },
              "margin_amount" => "5"
            },
          ]
        }
      }

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product)
      customer_carrier_product.create_sales_price!(use_margin_config: true, margin_config: margin_config)

      package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
        builder.add_package(length: 10, width: 10, height: 10, weight: 1.2)
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
        assert_equal BigDecimal("100.00"), line_item.cost_price_amount
        assert_equal BigDecimal("105.00"), line_item.sales_price_amount
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

      margin_config = CarrierProductMarginConfigurations::PerZoneAndRange.new
      margin_config.generate_price_document_hash(carrier_product_price: carrier_product.carrier_product_price)
      margin_config.config_document = {
        "zones" => {
          "0" => [
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1" },
              "margin_amount" => "10",
            },
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1.5" },
              "margin_amount" => "5"
            },
          ]
        }
      }

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product)
      customer_carrier_product.create_sales_price!(use_margin_config: true, margin_config: margin_config)

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
        assert_equal BigDecimal("100.00"), line_item.sales_price_amount
      end

      prices.first.advanced_price_line_items[1].tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("4.50"), line_item.cost_price_amount
        assert_equal BigDecimal("5.00"), line_item.sales_price_amount

        assert line_item.parameters
        assert_equal BigDecimal("100.00"), line_item.parameters[:base]
        assert_equal BigDecimal("5.00"), line_item.parameters[:percentage]
      end
    end

    test "shipment being sold directly to customer with fixed surcharge" do
      company = Company.create!(name: "A Company")
      customer = Customer.create!(name: "A Customer", company: company)

      carrier_product = CarrierProduct.create!(name: "Custom Carrier Product", company: company)
      carrier_product.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk_with_surcharge)

      margin_config = CarrierProductMarginConfigurations::PerZoneAndRange.new
      margin_config.generate_price_document_hash(carrier_product_price: carrier_product.carrier_product_price)
      margin_config.config_document = {
        "zones" => {
          "0" => [
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1" },
              "margin_amount" => "10",
            },
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1.5" },
              "margin_amount" => "5"
            },
          ]
        }
      }

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product)
      customer_carrier_product.create_sales_price!(use_margin_config: true, margin_config: margin_config)

      package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
        builder.add_package(length: 10, width: 10, height: 10, weight: 1.2)
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
        assert_equal BigDecimal("100.00"), line_item.cost_price_amount
        assert_equal BigDecimal("105.00"), line_item.sales_price_amount
      end

      prices.first.advanced_price_line_items[1].tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("40.00"), line_item.cost_price_amount
        assert_equal BigDecimal("40.00"), line_item.sales_price_amount
      end
    end

    test "shipment being sold by company.A to company.X (with a %margin) to customer (with a weight-level mark-up)" do
      company_a = Company.create!(name: "Company A")
      company_x = Company.create!(name: "Company X")

      customer = Customer.create!(name: "Customer", company: company_x)

      carrier_product_a = CarrierProduct.create!(name: "Custom Carrier Product", company: company_a, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_a.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      carrier_product_x = CarrierProduct.create!(carrier_product: carrier_product_a, company: company_x, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)
      carrier_product_x.create_sales_price!(margin_percentage: "10") # Company A earns 10%

      margin_config = CarrierProductMarginConfigurations::PerZoneAndRange.new
      margin_config.generate_price_document_hash(carrier_product_price: carrier_product_a.carrier_product_price)
      margin_config.config_document = {
        "zones" => {
          "0" => [
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1" },
              "margin_amount" => "10",
            },
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1.5" },
              "margin_amount" => "5"
            },
          ]
        }
      }

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product_x)
      customer_carrier_product.create_sales_price!(use_margin_config: true, margin_config: margin_config)

      package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product_x) do |builder|
        builder.add_package(length: 10, width: 10, height: 10, weight: 1)
      end

      prices = carrier_product_x.calculate_price_chain_for_shipment(
        company_id: company_x.id,
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
      assert_equal 2, prices.length

      prices[0].advanced_price_line_items.first.tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("90.00"), line_item.cost_price_amount
        assert_equal BigDecimal("99.00"), line_item.sales_price_amount
      end

      prices[1].advanced_price_line_items.first.tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("99.00"), line_item.cost_price_amount
        assert_equal BigDecimal("109.00"), line_item.sales_price_amount
      end
    end

    test "shipment being sold by company.A to company.X (with a weight-level mark-up) to customer (with a weight-level mark-up)" do
      company_a = Company.create!(name: "Company A")
      company_x = Company.create!(name: "Company X")

      customer = Customer.create!(name: "Customer", company: company_x)

      carrier_product_a = CarrierProduct.create!(name: "Custom Carrier Product", company: company_a, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_a.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      margin_config_a = CarrierProductMarginConfigurations::PerZoneAndRange.new
      margin_config_a.generate_price_document_hash(carrier_product_price: carrier_product_a.carrier_product_price)
      margin_config_a.config_document = {
        "zones" => {
          "0" => [
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1" },
              "margin_amount" => "20",
            },
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1.5" },
              "margin_amount" => "15"
            },
          ]
        }
      }

      carrier_product_x = CarrierProduct.create!(carrier_product: carrier_product_a, company: company_x, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)
      carrier_product_x.create_sales_price!(use_margin_config: true, margin_config: margin_config_a)

      margin_config_x = CarrierProductMarginConfigurations::PerZoneAndRange.new
      margin_config_x.generate_price_document_hash(carrier_product_price: carrier_product_a.carrier_product_price)
      margin_config_x.config_document = {
        "zones" => {
          "0" => [
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1" },
              "margin_amount" => "10",
            },
            {
              "charge_type" => "FlatWeightCharge",
              "weight" => { "value" => "1.5" },
              "margin_amount" => "5"
            },
          ]
        }
      }

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product_x)
      customer_carrier_product.create_sales_price!(use_margin_config: true, margin_config: margin_config_x)

      package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product_x) do |builder|
        builder.add_package(length: 10, width: 10, height: 10, weight: 1)
      end

      prices = carrier_product_x.calculate_price_chain_for_shipment(
        company_id: company_x.id,
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
      assert_equal 2, prices.length

      prices[0].advanced_price_line_items.first.tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("90.00"), line_item.cost_price_amount
        assert_equal BigDecimal("110.00"), line_item.sales_price_amount
      end

      prices[1].advanced_price_line_items.first.tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("110.00"), line_item.cost_price_amount
        assert_equal BigDecimal("120.00"), line_item.sales_price_amount
      end
    end
  end
end

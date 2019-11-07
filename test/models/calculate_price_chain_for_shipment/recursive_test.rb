require "test_helper"

module CalculatePriceChainForShipment
  class RecursiveTest < ActiveSupport::TestCase
    test "shipment being sold by company.A to company.X to customer" do
      company_a = Company.create!(name: "Company A")
      company_x = Company.create!(name: "Company X")

      customer = Customer.create!(name: "Customer", company: company_x)

      carrier_product_a = CarrierProduct.create!(name: "Custom Carrier Product", company: company_a, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_a.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      carrier_product_x = CarrierProduct.create!(carrier_product: carrier_product_a, company: company_x, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)
      carrier_product_x.create_sales_price!(margin_percentage: "10") # Company A earns 10%

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product_x)
      customer_carrier_product.create_sales_price!(margin_percentage: "50") # Company X earns 50%

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
        assert_equal BigDecimal("148.50"), line_item.sales_price_amount
      end
    end

    test "shipment being sold by company.A to company.X to customer (with fuelcharge)" do
      company_a = Company.create!(name: "Company A")
      company_x = Company.create!(name: "Company X")

      customer = Customer.create!(name: "Customer", company: company_x)

      carrier = Carrier.create!(name: "Custom Carrier")
      carrier_product_a = CarrierProduct.create!(name: "Custom Carrier Product", company: company_a, carrier: carrier, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_a.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      surcharge_on_carrier = carrier.find_fuel_charge
      surcharge_on_carrier.assign_attributes(calculation_method: "price_percentage", charge_value: "15", enabled: true)
      surcharge_on_carrier.save!

      carrier_product_x = CarrierProduct.create!(carrier_product: carrier_product_a, company: company_x, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)
      carrier_product_x.create_sales_price!(margin_percentage: "10") # Company A earns 10%

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product_x)
      customer_carrier_product.create_sales_price!(margin_percentage: "50") # Company X earns 50%

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

      assert_equal 2, prices[0].advanced_price_line_items.length
      assert_equal 2, prices[1].advanced_price_line_items.length

      prices[0].advanced_price_line_items[0].tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("90.00"), line_item.cost_price_amount
        assert_equal BigDecimal("99.00"), line_item.sales_price_amount
      end

      prices[0].advanced_price_line_items[1].tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("13.50"), line_item.cost_price_amount
        assert_equal BigDecimal("14.85"), line_item.sales_price_amount
      end

      prices[1].advanced_price_line_items.first.tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("99.00"), line_item.cost_price_amount
        assert_equal BigDecimal("148.50"), line_item.sales_price_amount
      end

      prices[1].advanced_price_line_items[1].tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("14.85"), line_item.cost_price_amount
        assert_equal BigDecimal("22.275"), line_item.sales_price_amount
      end
    end

    test "shipment being sold by company.A to to company.B to company.X to customer" do
      company_a = Company.create!(name: "Company A")
      company_b = Company.create!(name: "Company B")
      company_x = Company.create!(name: "Company X")

      customer = Customer.create!(name: "Customer", company: company_x)

      carrier_product_a = CarrierProduct.create!(name: "Custom Carrier Product", company: company_a, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_a.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      carrier_product_b = CarrierProduct.create!(carrier_product: carrier_product_a, company: company_a, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)
      carrier_product_b.create_sales_price!(margin_percentage: "10") # Company A earns 10%

      carrier_product_x = CarrierProduct.create!(carrier_product: carrier_product_b, company: company_x, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)
      carrier_product_x.create_sales_price!(margin_percentage: "20") # Company B earns 10%

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product_x)
      customer_carrier_product.create_sales_price!(margin_percentage: "50") # Company X earns 50%

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
      assert_equal 3, prices.length

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
        assert_equal BigDecimal("118.80"), line_item.sales_price_amount
      end

      prices[2].advanced_price_line_items.first.tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("118.80"), line_item.cost_price_amount
        assert_equal BigDecimal("178.20"), line_item.sales_price_amount
      end
    end

    test "non-custom shipment being _offered_ by company.CF to company.X to customer" do
      company_cf = Company.create!(name: "CargoFlux")
      company_x = Company.create!(name: "Company X")

      customer = Customer.create!(name: "Customer", company: company_x)

      carrier_product_class = DHLExpressCarrierProduct

      carrier_product_cf = carrier_product_class.create!(name: "DHL Express", company: company_cf, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

      carrier_product_x = carrier_product_class.create!(carrier_product: carrier_product_cf, company: company_x, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_x.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product_x)
      customer_carrier_product.create_sales_price!(margin_percentage: "25") # Company X earns 25%

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
      assert_equal 1, prices.length

      prices[0].advanced_price_line_items.first.tap do |line_item|
        assert_equal 1, line_item.times
        assert_equal "automatic", line_item.price_type
        assert_equal BigDecimal("90.00"), line_item.cost_price_amount
        assert_equal BigDecimal("112.50"), line_item.sales_price_amount
      end
    end

    test "non-custom shipment being sold by company.A to company.X to customer" do
      company_a = Company.create!(name: "Company A")
      company_x = Company.create!(name: "Company X")

      customer = Customer.create!(name: "Customer", company: company_x)

      carrier_product_class = GLSBusinessCarrierProduct

      carrier_product_a = carrier_product_class.create!(name: "GLS Business", company: company_a, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_a.create_carrier_product_price!(state: "ok", price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

      carrier_product_x = carrier_product_class.create!(carrier_product: carrier_product_a, company: company_x, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)
      carrier_product_x.create_sales_price!(margin_percentage: "10") # Company A earns 10%

      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product_x)
      customer_carrier_product.create_sales_price!(margin_percentage: "50") # Company X earns 50%

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

      assert_equal 1, prices.length
    end
  end
end

require "test_helper"

class GetPricesTest < ActiveSupport::TestCase
  setup do
    company = Company.create!(name: "Company")
    customer = company.customers.create!(name: "Customer")

    carrier = Carrier.create!(company: company, name: "My Carrier")

    carrier_products = [
      CarrierProduct.create!(carrier: carrier, name: "My Express Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING),
      CarrierProduct.create!(carrier: carrier, name: "My Saver Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING),
      CarrierProduct.create!(carrier: carrier, name: "My Standard Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING),
    ]

    CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_products[0], sales_price: SalesPrice.new(margin_percentage: "0.0"))
    CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_products[1], sales_price: SalesPrice.new(margin_percentage: "0.0"))
    CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_products[2], sales_price: SalesPrice.new(), is_disabled: true)

    @company, @customer, @carrier_products = company, customer, carrier_products
  end

  test "without carrier product rules" do
    sender_params = {
      country_code: "dk",
      city: "Copenhagen",
      zip_code: "2300",
      address_line1: "...",
      address_line2: nil,
    }

    recipient_params = {
      country_code: "dk",
      city: "Næstved",
      zip_code: "4700",
      address_line1: "...",
      address_line2: nil,
    }

    interactor =
      Shared::Shipments::GetPrices.new(
        company_id: @company.id,
        customer_id: @customer.id,
        sender_params: sender_params,
        recipient_params: recipient_params,
        shipment_type: "Export",
        dangerous_goods: false,
        residential: false,
        package_dimensions: {},
        custom_products_only: false,
        chain: true,
      )

    assert_interactor_result interactor: interactor, expected_carrier_products: [@carrier_products[0], @carrier_products[1]]
  end

  test "with carrier product rules, shipment weight interval" do
    # Create a rule on  "My Express Product": shipment weight must be 20 kg at most.
    rule_1 = CarrierProductRule.new(carrier_product: @carrier_products[0])
    rule_1.shipment_weight_interval.attributes = { enabled: true, to: "20.0", to_inclusive: false }
    rule_1.save!

    # Create a rule on  "My Saver Product": shipment weight must be more than 10 kg.
    rule_2 = CarrierProductRule.new(carrier_product: @carrier_products[1])
    rule_2.shipment_weight_interval.attributes = { enabled: true, from: "10.0", from_inclusive: true }
    rule_2.save!

    sender_params = {
      country_code: "dk",
      city: "Copenhagen",
      zip_code: "2300",
      address_line1: "...",
      address_line2: nil,
    }

    recipient_params = {
      country_code: "dk",
      city: "Næstved",
      zip_code: "4700",
      address_line1: "...",
      address_line2: nil,
    }

    package_dimensions = {
      "0" => {
        amount: "1",
        length: "10",
        width: "10",
        height: "10",
        weight: "10.5",
      },
      "1" => {
        amount: "1",
        length: "11",
        width: "11",
        height: "11",
        weight: "10.0",
      },
    }

    interactor =
      Shared::Shipments::GetPrices.new(
        company_id: @company.id,
        customer_id: @customer.id,
        sender_params: sender_params,
        recipient_params: recipient_params,
        shipment_type: "Export",
        dangerous_goods: false,
        residential: false,
        package_dimensions: package_dimensions,
        custom_products_only: false,
        chain: true,
      )

    assert_interactor_result interactor: interactor, expected_carrier_products: [@carrier_products[1]]
  end

  test "with carrier product rules, package count interval" do
    # Create a rule on  "My Express Product": package count must be more than 5.
    rule_1 = CarrierProductRule.new(carrier_product: @carrier_products[0])
    rule_1.number_of_packages_interval.attributes = { enabled: true, from: "5", from_inclusive: true }
    rule_1.save!

    # Create a rule on  "My Saver Product": package count must be 7 at most.
    rule_2 = CarrierProductRule.new(carrier_product: @carrier_products[1])
    rule_2.number_of_packages_interval.attributes = { enabled: true, to: "7", to_inclusive: false }
    rule_2.save!

    sender_params = {
      country_code: "dk",
      city: "Copenhagen",
      zip_code: "2300",
      address_line1: "...",
      address_line2: nil,
    }

    recipient_params = {
      country_code: "dk",
      city: "Næstved",
      zip_code: "4700",
      address_line1: "...",
      address_line2: nil,
    }

    package_dimensions = {
      "0" => {
        amount: "7",
        length: "10",
        width: "10",
        height: "10",
        weight: "0.1",
      },
      "1" => {
        amount: "1",
        length: "11",
        width: "11",
        height: "11",
        weight: "1",
      },
    }

    interactor =
      Shared::Shipments::GetPrices.new(
        company_id: @company.id,
        customer_id: @customer.id,
        sender_params: sender_params,
        recipient_params: recipient_params,
        shipment_type: "Export",
        dangerous_goods: false,
        residential: false,
        package_dimensions: package_dimensions,
        custom_products_only: false,
        chain: true,
      )

    assert_interactor_result interactor: interactor, expected_carrier_products: [@carrier_products[0]]
  end

  test "with carrier product rules, recipient location" do
    # Create a rule on  "My Express Product": recipient must be in EU
    rule_1 = CarrierProductRule.new(carrier_product: @carrier_products[0])
    rule_1.recipient_match_enabled = true
    rule_1.recipient_location_value = "within_eu"
    rule_1.save!

    # Create a rule on  "My Saver Product": recipient must be outside EU
    rule_2 = CarrierProductRule.new(carrier_product: @carrier_products[1])
    rule_2.recipient_match_enabled = true
    rule_2.recipient_location_value = "outside_eu"
    rule_2.save!

    sender_params = {
      country_code: "dk",
      city: "Copenhagen",
      zip_code: "2300",
      address_line1: "...",
      address_line2: nil,
    }

    recipient_params = {
      country_code: "dk",
      city: "Næstved",
      zip_code: "4700",
      address_line1: "...",
      address_line2: nil,
    }

    interactor =
      Shared::Shipments::GetPrices.new(
        company_id: @company.id,
        customer_id: @customer.id,
        sender_params: sender_params,
        recipient_params: recipient_params,
        shipment_type: "Export",
        dangerous_goods: false,
        residential: false,
        package_dimensions: {},
        custom_products_only: false,
        chain: true,
      )

    assert_interactor_result interactor: interactor, expected_carrier_products: [@carrier_products[0]]
  end

  test "does not use carrier product rules on parent product" do
    # Disable 1st product, as we'll only focus on the 0th
    CustomerCarrierProduct.where(customer: @customer, carrier_product: @carrier_products[1]).update_all(is_disabled: true)

    carrier_product = @carrier_products[0]
    carrier = @carrier_products[0].carrier

    parent_company = Company.create!(name: "Parent Company")

    parent_carrier = carrier.dup
    parent_carrier.attributes = { company: parent_company }
    parent_carrier.save!
    carrier.update!(carrier: parent_carrier, name: nil)

    parent_carrier_product = carrier_product.dup
    parent_carrier_product.attributes = { company: parent_company }
    parent_carrier_product.save!
    carrier_product.update!(carrier_product: parent_carrier_product, name: nil, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)

    # Create a rule on "My Express Product": recipient must be in EU
    rule_1 = CarrierProductRule.new(carrier_product: carrier_product)
    rule_1.recipient_match_enabled = true
    rule_1.recipient_location_value = "within_eu"
    rule_1.save!

    # Create a rule on *parent* of "My Express Product": shipment weight must be at least 10 kg
    rule_2 = CarrierProductRule.new(carrier_product: parent_carrier_product)
    rule_2.shipment_weight_interval.attributes = { enabled: true, from: "10.0", from_inclusive: true }
    rule_2.save!

    sender_params = {
      country_code: "dk",
      city: "Copenhagen",
      zip_code: "2300",
      address_line1: "...",
      address_line2: nil,
    }

    recipient_params = {
      country_code: "dk",
      city: "Næstved",
      zip_code: "4700",
      address_line1: "...",
      address_line2: nil,
    }

    package_dimensions = {
      "0" => {
        amount: "1",
        length: "10",
        width: "10",
        height: "10",
        weight: "5.0",
      },
    }

    interactor =
      Shared::Shipments::GetPrices.new(
        company_id: @company.id,
        customer_id: @customer.id,
        sender_params: sender_params,
        recipient_params: recipient_params,
        shipment_type: "Export",
        dangerous_goods: false,
        residential: false,
        package_dimensions: package_dimensions,
        custom_products_only: false,
        chain: true,
      )

    assert_interactor_result interactor: interactor, expected_carrier_products: [carrier_product]
  end

  private

  def assert_interactor_result(interactor:, expected_carrier_products:)
    interactor_result = interactor.run

    if (e = interactor_result.try(:error))
      raise e
    end

    assert_equal \
      Set.new(expected_carrier_products.map(&:id)),
      Set.new(interactor_result.carrier_products_and_prices.map { |i| i[:carrier_product_id] })
  end
end

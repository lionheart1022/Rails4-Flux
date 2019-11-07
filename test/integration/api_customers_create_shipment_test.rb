require "test_helper"

class APICustomersCreateShipmentTest < ActionDispatch::IntegrationTest
  test "create a regular shipment successfully" do
    company = setup_company!
    customer = setup_customer!(company: company)
    carrier_product = setup_carrier_product!(company: company, customers: [customer])
    access_token = AccessToken.create!(owner: customer, value: SecureRandom.hex)

    request_params = {
      "access_token" => access_token.value,
      "callback_url" => "https://example.com/bookings/callback",
      "return_label" => false,
      "shipment" => {
        "product_code" => carrier_product.product_code,
        "dutiable" => false,
        "package_dimensions" => [
          {
            "amount" => "1",
            "height" => "10",
            "length" => "10",
            "weight" => "5",
            "width" => "10",
          },
        ],
        "description" => "some customer description",
        "reference" => "some customer reference",
        "shipping_date" => Date.today.to_s,
      },
      "sender" => {
        "address_line1" => "some street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "Jack",
        "city" => "Copenhagen",
        "company_name" => "Some company",
        "country_code" => "DK",
        "email" => "sender@example.com",
        "phone_number" => "33333333",
        "state_code" => "",
        "zip_code" => "2300",
      },
      "recipient" => {
        "address_line1" => "some other street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "George",
        "city" => "Copenhagen",
        "company_name" => "Some other company",
        "country_code" => "DK",
        "email" => "recipient@example.com",
        "phone_number" => "44444444",
        "state_code" => "",
        "zip_code" => "2300",
      },
    }

    post "/api/v1/customers/shipments", JSON.generate(request_params), { "Content-Type" => "application/json" }

    assert_equal 200, status

    json_response = JSON.parse(response.body)
    shipment = Shipment.find_by_unique_shipment_id!(json_response["unique_shipment_id"])

    assert_equal "created", json_response["status"]
    refute shipment.pickup_relation
  end

  test "create a DGR shipment successfully" do
    company = setup_company!
    customer = setup_customer!(company: company)
    customer.update!(allow_dangerous_goods: true) # this needs to be enabled for DGR to be allowed
    carrier_product = setup_carrier_product!(company: company, customers: [customer])
    access_token = AccessToken.create!(owner: customer, value: SecureRandom.hex)

    request_params = {
      "access_token" => access_token.value,
      "callback_url" => "https://example.com/bookings/callback",
      "return_label" => false,
      "shipment" => {
        "product_code" => carrier_product.product_code,
        "dutiable" => false,
        "package_dimensions" => [
          {
            "amount" => "1",
            "height" => "10",
            "length" => "10",
            "weight" => "5",
            "width" => "10",
          },
        ],
        "description" => "some customer description",
        "reference" => "some customer reference",
        "shipping_date" => Date.today.to_s,
        "dgr" => {
          "enabled" => true,
          "identifier" => "dry_ice",
        }
      },
      "sender" => {
        "address_line1" => "some street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "Jack",
        "city" => "Copenhagen",
        "company_name" => "Some company",
        "country_code" => "DK",
        "email" => "sender@example.com",
        "phone_number" => "33333333",
        "state_code" => "",
        "zip_code" => "2300",
      },
      "recipient" => {
        "address_line1" => "some other street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "George",
        "city" => "Copenhagen",
        "company_name" => "Some other company",
        "country_code" => "DK",
        "email" => "recipient@example.com",
        "phone_number" => "44444444",
        "state_code" => "",
        "zip_code" => "2300",
      },
    }

    post "/api/v1/customers/shipments", JSON.generate(request_params), { "Content-Type" => "application/json" }

    assert_equal 200, status

    json_response = JSON.parse(response.body)
    shipment = Shipment.find_by_unique_shipment_id!(json_response["unique_shipment_id"])

    assert_equal "created", json_response["status"]
    assert shipment.dangerous_goods?
    assert_equal "dry_ice", shipment.dangerous_goods_predefined_option
  end

  test "create a shipment with auto-pickup successfully" do
    company = setup_company!
    customer = setup_customer!(company: company)
    carrier_product = setup_carrier_product!(company: company, customers: [customer])
    access_token = AccessToken.create!(owner: customer, value: SecureRandom.hex)

    CustomerCarrierProduct
      .find_by!(customer: customer, carrier_product: carrier_product, is_disabled: false)
      .update!(allow_auto_pickup: true)

    request_params = {
      "access_token" => access_token.value,
      "callback_url" => "https://example.com/bookings/callback",
      "return_label" => false,
      "shipment" => {
        "product_code" => carrier_product.product_code,
        "dutiable" => false,
        "package_dimensions" => [
          {
            "amount" => "1",
            "height" => "10",
            "length" => "10",
            "weight" => "5",
            "width" => "10",
          },
        ],
        "description" => "some customer description",
        "reference" => "some customer reference",
        "shipping_date" => Date.today.to_s,
      },
      "sender" => {
        "address_line1" => "some street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "Jack",
        "city" => "Copenhagen",
        "company_name" => "Some company",
        "country_code" => "DK",
        "email" => "sender@example.com",
        "phone_number" => "33333333",
        "state_code" => "",
        "zip_code" => "2300",
      },
      "recipient" => {
        "address_line1" => "some other street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "George",
        "city" => "Copenhagen",
        "company_name" => "Some other company",
        "country_code" => "DK",
        "email" => "recipient@example.com",
        "phone_number" => "44444444",
        "state_code" => "",
        "zip_code" => "2300",
      },
      "pickup" => {
        "enabled" => true,
        "from_time" => "13:00",
        "to_time" => "18:00",
      }
    }

    post "/api/v1/customers/shipments", JSON.generate(request_params), { "Content-Type" => "application/json" }

    assert_equal 200, status

    json_response = JSON.parse(response.body)
    shipment = Shipment.find_by_unique_shipment_id!(json_response["unique_shipment_id"])

    assert_equal "created", json_response["status"]
    assert shipment.pickup_relation
    assert_equal request_params["sender"]["company_name"], shipment.pickup_relation.contact.company_name
  end

  test "create a shipment with number_of_pallets successfully" do
    company = setup_company!
    customer = setup_customer!(company: company)
    carrier_product = setup_carrier_product!(company: company, customers: [customer])
    access_token = AccessToken.create!(owner: customer, value: SecureRandom.hex)

    CustomerCarrierProduct
      .find_by!(customer: customer, carrier_product: carrier_product, is_disabled: false)
      .update!(allow_auto_pickup: true)

    request_params = {
      "access_token" => access_token.value,
      "callback_url" => "https://example.com/bookings/callback",
      "return_label" => false,
      "shipment" => {
        "product_code" => carrier_product.product_code,
        "dutiable" => false,
        "number_of_pallets" => 4,
        "package_dimensions" => [
          {
            "amount" => "1",
            "height" => "10",
            "length" => "10",
            "weight" => "5",
            "width" => "10",
          },
        ],
        "description" => "some customer description",
        "reference" => "some customer reference",
        "shipping_date" => Date.today.to_s,
      },
      "sender" => {
        "address_line1" => "some street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "Jack",
        "city" => "Copenhagen",
        "company_name" => "Some company",
        "country_code" => "DK",
        "email" => "sender@example.com",
        "phone_number" => "33333333",
        "state_code" => "",
        "zip_code" => "2300",
      },
      "recipient" => {
        "address_line1" => "some other street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "George",
        "city" => "Copenhagen",
        "company_name" => "Some other company",
        "country_code" => "DK",
        "email" => "recipient@example.com",
        "phone_number" => "44444444",
        "state_code" => "",
        "zip_code" => "2300",
      },
      "pickup" => {
        "enabled" => true,
        "from_time" => "13:00",
        "to_time" => "18:00",
      }
    }

    post "/api/v1/customers/shipments", JSON.generate(request_params), { "Content-Type" => "application/json" }

    assert_equal 200, status

    json_response = JSON.parse(response.body)
    shipment = Shipment.find_by_unique_shipment_id!(json_response["unique_shipment_id"])

    assert_equal "created", json_response["status"]
    assert_equal 4, shipment.number_of_pallets
    assert shipment.pickup_relation
    assert_equal request_params["sender"]["company_name"], shipment.pickup_relation.contact.company_name
  end

  test "create a regular shipment with default sender" do
    company = setup_company!
    customer = setup_customer!(company: company)
    carrier_product = setup_carrier_product!(company: company, customers: [customer])
    access_token = AccessToken.create!(owner: customer, value: SecureRandom.hex)

    request_params = {
      "access_token" => access_token.value,
      "callback_url" => "https://example.com/bookings/callback",
      "return_label" => false,
      "shipment" => {
        "product_code" => carrier_product.product_code,
        "dutiable" => false,
        "package_dimensions" => [
          {
            "amount" => "1",
            "height" => "10",
            "length" => "10",
            "weight" => "5",
            "width" => "10",
          },
        ],
        "description" => "some customer description",
        "reference" => "some customer reference",
        "shipping_date" => Date.today.to_s,
      },
      "default_sender" => true,
      "recipient" => {
        "address_line1" => "some other street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "George",
        "city" => "Copenhagen",
        "company_name" => "Some other company",
        "country_code" => "DK",
        "email" => "recipient@example.com",
        "phone_number" => "44444444",
        "state_code" => "",
        "zip_code" => "2300",
      },
    }

    post "/api/v1/customers/shipments", JSON.generate(request_params), { "Content-Type" => "application/json" }
    assert_equal 200, status

    json_response = JSON.parse(response.body)
    shipment = Shipment.find_by_unique_shipment_id!(json_response["unique_shipment_id"])

    assert_equal "created", json_response["status"]
    refute shipment.pickup_relation
  end

  test "creating shipment without product code should fail" do
    company = setup_company!
    customer = setup_customer!(company: company)
    carrier_product = setup_carrier_product!(company: company, customers: [customer])
    access_token = AccessToken.create!(owner: customer, value: SecureRandom.hex)

    CustomerCarrierProduct
      .find_by!(customer: customer, carrier_product: carrier_product, is_disabled: false)
      .update!(allow_auto_pickup: true)

    request_params = {
      "access_token" => access_token.value,
      "callback_url" => "https://example.com/bookings/callback",
      "return_label" => false,
      "shipment" => {
        "dutiable" => false,
        "package_dimensions" => [
          {
            "amount" => "1",
            "height" => "10",
            "length" => "10",
            "weight" => "5",
            "width" => "10",
          },
        ],
        "description" => "some customer description",
        "reference" => "some customer reference",
        "shipping_date" => Date.today.to_s,
      },
      "sender" => {
        "address_line1" => "some street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "Jack",
        "city" => "Copenhagen",
        "company_name" => "Some company",
        "country_code" => "DK",
        "email" => "sender@example.com",
        "phone_number" => "33333333",
        "state_code" => "",
        "zip_code" => "2300",
      },
      "recipient" => {
        "address_line1" => "some other street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "George",
        "city" => "Copenhagen",
        "company_name" => "Some other company",
        "country_code" => "DK",
        "email" => "recipient@example.com",
        "phone_number" => "44444444",
        "state_code" => "",
        "zip_code" => "2300",
      },
      "pickup" => {
        "enabled" => true,
        "from_time" => "13:00",
        "to_time" => "18:00",
      }
    }

    post "/api/v1/customers/shipments", JSON.generate(request_params), { "Content-Type" => "application/json" }

    assert_equal 500, status

    json_response = JSON.parse(response.body)

    assert_equal "failed", json_response["status"]
    assert_equal 1, json_response["errors"].count
    assert_equal "CF-API-003", json_response["errors"][0]["code"]
  end

  test "creating shipment with invalid sender country code should fail" do
    company = setup_company!
    customer = setup_customer!(company: company)
    carrier_product = setup_carrier_product!(company: company, customers: [customer])
    access_token = AccessToken.create!(owner: customer, value: SecureRandom.hex)

    request_params = {
      "access_token" => access_token.value,
      "callback_url" => "https://example.com/bookings/callback",
      "return_label" => false,
      "shipment" => {
        "product_code" => carrier_product.product_code,
        "dutiable" => false,
        "package_dimensions" => [
          {
            "amount" => "1",
            "height" => "10",
            "length" => "10",
            "weight" => "5",
            "width" => "10",
          },
        ],
        "description" => "some customer description",
        "reference" => "some customer reference",
        "shipping_date" => Date.today.to_s,
      },
      "sender" => {
        "address_line1" => "some street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "Jack",
        "city" => "Copenhagen",
        "company_name" => "Some company",
        "country_code" => "DNMRK",
        "email" => "sender@example.com",
        "phone_number" => "33333333",
        "state_code" => "",
        "zip_code" => "2300",
      },
      "recipient" => {
        "address_line1" => "some other street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "George",
        "city" => "Copenhagen",
        "company_name" => "Some other company",
        "country_code" => "DK",
        "email" => "recipient@example.com",
        "phone_number" => "44444444",
        "state_code" => "",
        "zip_code" => "2300",
      },
    }

    post "/api/v1/customers/shipments", JSON.generate(request_params), { "Content-Type" => "application/json" }

    assert_equal 500, status

    json_response = JSON.parse(response.body)

    assert_equal "failed", json_response["status"]
    assert_equal 1, json_response["errors"].count
    assert_nil json_response["errors"][0]["code"]
    assert_equal "Invalid sender field: country code", json_response["errors"][0]["description"]
  end

  test "creating shipment with invalid recipient country code should fail" do
    company = setup_company!
    customer = setup_customer!(company: company)
    carrier_product = setup_carrier_product!(company: company, customers: [customer])
    access_token = AccessToken.create!(owner: customer, value: SecureRandom.hex)

    request_params = {
      "access_token" => access_token.value,
      "callback_url" => "https://example.com/bookings/callback",
      "return_label" => false,
      "shipment" => {
        "product_code" => carrier_product.product_code,
        "dutiable" => false,
        "package_dimensions" => [
          {
            "amount" => "1",
            "height" => "10",
            "length" => "10",
            "weight" => "5",
            "width" => "10",
          },
        ],
        "description" => "some customer description",
        "reference" => "some customer reference",
        "shipping_date" => Date.today.to_s,
      },
      "sender" => {
        "address_line1" => "some street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "Jack",
        "city" => "Copenhagen",
        "company_name" => "Some company",
        "country_code" => "DK",
        "email" => "sender@example.com",
        "phone_number" => "33333333",
        "state_code" => "",
        "zip_code" => "2300",
      },
      "recipient" => {
        "address_line1" => "some other street",
        "address_line2" => "",
        "address_line3" => "",
        "attention" => "George",
        "city" => "Copenhagen",
        "company_name" => "Some other company",
        "country_code" => "DNKMRK",
        "email" => "recipient@example.com",
        "phone_number" => "44444444",
        "state_code" => "",
        "zip_code" => "2300",
      },
    }

    post "/api/v1/customers/shipments", JSON.generate(request_params), { "Content-Type" => "application/json" }

    assert_equal 500, status

    json_response = JSON.parse(response.body)

    assert_equal "failed", json_response["status"]
    assert_equal 1, json_response["errors"].count
    assert_nil json_response["errors"][0]["code"]
    assert_equal "Invalid recipient field: country code", json_response["errors"][0]["description"]
  end

  private

  def setup_company!
    Company.create_cargoflux_company!(name: "CargoFlux ApS", current_customer_id: 0, current_report_id: 0)
    Company.create_direct_company!(name: "Company A", current_customer_id: 0, current_report_id: 0)
  end

  def setup_customer!(company:)
    customer = Customer.new(name: "Test Customer 1", company: company, customer_id: company.update_next_customer_id)
    customer.build_address(company_name: "Test Customer A", attention: "Test Person", address_line1: "Njalsgade 17A", zip_code: "2300", city: "København S", country_code: "dk", country_name: "Denmark")
    customer.save!

    customer
  end

  def setup_carrier_product!(company:, customers: [])
    carrier_product = CarrierProduct.new(company: company, name: "Custom Product 1", product_code: "cp1", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
    carrier_product.build_carrier(company: company, name: "Custom Carrier 1")
    carrier_product.save!

    customers.each do |customer|
      customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product, is_disabled: false)
      SalesPrice.create!(margin_percentage: "0.0", reference: customer_carrier_product)
    end

    carrier_product
  end
end

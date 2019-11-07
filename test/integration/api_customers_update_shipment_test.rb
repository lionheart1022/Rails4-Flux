require "test_helper"

class APICustomersUpdateShipmentTest < ActionDispatch::IntegrationTest
  test "updating a shipment" do
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

    # First we create the shipment
    post "/api/v1/customers/shipments", JSON.generate(request_params), { "Content-Type" => "application/json" }

    assert_equal 200, status

    json_response = JSON.parse(response.body)
    shipment = Shipment.find_by_unique_shipment_id!(json_response["unique_shipment_id"])

    # Mark the shipment as failed, otherwise the update will fail
    shipment.update!(state: Shipment::States::BOOKING_FAILED)

    # Then we update it
    update_request_params = {
      "access_token" => access_token.value,
      "unique_shipment_id" => json_response["unique_shipment_id"],
      "callback_url" => "https://example.com/bookings/callback",
      "return_label" => false,
      "shipment" => {
        "product_code" => carrier_product.product_code,
        "dutiable" => false,
        "package_dimensions" => [
          {
            "amount" => "4",
            "height" => "10",
            "length" => "10",
            "weight" => "5",
            "width" => "10",
          },
          {
            "amount" => "7",
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

    put "/api/v1/customers/shipments", JSON.generate(update_request_params), { "Content-Type" => "application/json" }

    assert_equal 200, status

    shipment.reload

    assert_equal 11, shipment.number_of_packages
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

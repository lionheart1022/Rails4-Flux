require "test_helper"

module Companies
  class ShipmentsControllerGetCarrierProductsAndPricesForShipmentTest < ActionController::TestCase
    tests ShipmentsController
    include Devise::TestHelpers

    test "get_carrier_products_and_prices_for_shipment for customer with products without prices" do
      company = ::Company.create!(name: "A Company")
      customer = ::Customer.create!(name: "A Customer", company: company)
      user = ::User.create!(company: company, email: "user@example.com", password: "password", confirmed_at: Time.now)
      sign_in user

      carrier = Carrier.create!(company: company, name: "A Carrier")
      carrier_product_1 = CarrierProduct.create!(company: company, carrier: carrier, name: "Product 1", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_2 = CarrierProduct.create!(company: company, carrier: carrier, name: "Product 2", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_3 = CarrierProduct.create!(company: company, carrier: carrier, name: "Product 3", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

      CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product_1, is_disabled: false)
      CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product_2, is_disabled: false)

      sender_params = {
        address_line1: "Njalsgade 17A",
        zip_code: "2300",
        city: "København S",
        country_name: "Denmark",
        country_code: "DK",
      }

      recipient_params = {
        address_line1: "Åstvej 1",
        zip_code: "7190",
        city: "Billund",
        country_name: "Denmark",
        country_code: "DK",
      }

      package_dimensions_params = {
        "0" => {
          "amount" => "1",
          "length" => "1000",
          "width" => "100",
          "height" => "10",
          "weight" => "1.5",
        }
      }

      post(
        :get_carrier_products_and_prices_for_shipment,
        format: "json",
        customer_id: customer.id,
        sender: sender_params,
        recipient: recipient_params,
        package_dimensions: package_dimensions_params,
      )

      assert_response :success

      json_response = JSON.parse(response.body)

      assert json_response["html"]
      assert_nil json_response["digest"]
      assert_equal json_response["should_show_route"], false

      html = Nokogiri::HTML(json_response["html"])
      product_rows = html.css("table tr:not(:first-child)") # skip the first header row

      assert_equal 2, product_rows.count

      assert_equal "Product 1", product_rows[0].at_css("td:nth-child(2)").text
      assert_equal "N/A", product_rows[0].at_css("td:nth-child(3)").text

      assert_equal "Product 2", product_rows[1].at_css("td:nth-child(2)").text
      assert_equal "N/A", product_rows[1].at_css("td:nth-child(3)").text
    end

    test "get_carrier_products_and_prices_for_shipment for customer with products with prices" do
      company = ::Company.create!(name: "A Company")
      customer = ::Customer.create!(name: "A Customer", company: company)
      user = ::User.create!(company: company, email: "user@example.com", password: "password", confirmed_at: Time.now)
      sign_in user

      carrier = Carrier.create!(company: company, name: "A Carrier")
      carrier_product_1 = CarrierProduct.create!(company: company, carrier: carrier, name: "Product 1", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_2 = CarrierProduct.create!(company: company, carrier: carrier, name: "Product 2", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_3 = CarrierProduct.create!(company: company, carrier: carrier, name: "Product 3", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

      price_document = TestPriceDocuments.price_single_1kg_single_zone_dk

      carrier_product_1_price_document = price_document
      carrier_product_2_price_document = price_document
      carrier_product_3_price_document = price_document

      carrier_product_1_price = CarrierProductPrice.create!(carrier_product: carrier_product_1, price_document: carrier_product_1_price_document, state: carrier_product_1_price_document.state)
      carrier_product_2_price = CarrierProductPrice.create!(carrier_product: carrier_product_2, price_document: carrier_product_2_price_document, state: carrier_product_2_price_document.state)
      carrier_product_3_price = CarrierProductPrice.create!(carrier_product: carrier_product_3, price_document: carrier_product_3_price_document, state: carrier_product_3_price_document.state)

      customer_carrier_product_1 = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product_1, is_disabled: false)
      customer_carrier_product_2 = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product_2, is_disabled: false)

      SalesPrice.create!(reference: customer_carrier_product_1, margin_percentage: 10.0)
      SalesPrice.create!(reference: customer_carrier_product_2, margin_percentage: 20.0)

      sender_params = {
        address_line1: "Njalsgade 17A",
        zip_code: "2300",
        city: "København S",
        country_name: "Denmark",
        country_code: "DK",
      }

      recipient_params = {
        address_line1: "Åstvej 1",
        zip_code: "7190",
        city: "Billund",
        country_name: "Denmark",
        country_code: "DK",
      }

      package_dimensions_params = {
        "0" => {
          "amount" => "1",
          "length" => "1000",
          "width" => "100",
          "height" => "10",
          "weight" => "1.5",
        }
      }

      post(
        :get_carrier_products_and_prices_for_shipment,
        format: "json",
        customer_id: customer.id,
        sender: sender_params,
        recipient: recipient_params,
        package_dimensions: package_dimensions_params,
      )

      assert_response :success

      json_response = JSON.parse(response.body)

      assert json_response["html"]
      assert_nil json_response["digest"]
      assert_equal json_response["should_show_route"], false

      html = Nokogiri::HTML(json_response["html"])
      product_rows = html.css("table tr:not(:first-child)") # skip the first header row

      assert_equal 2, product_rows.count

      assert_equal "Product 1", product_rows[0].at_css("td:nth-child(2)").text
      assert_equal "carrier_product_price", product_rows[0].at_css("td:nth-child(3)")["class"]
      assert_equal "DKK 110.00", product_rows[0].at_css("td:nth-child(3)").text

      assert_equal "Product 2", product_rows[1].at_css("td:nth-child(2)").text
      assert_equal "carrier_product_price", product_rows[1].at_css("td:nth-child(3)")["class"]
      assert_equal "DKK 120.00", product_rows[1].at_css("td:nth-child(3)").text
    end

    test "get_carrier_products_and_prices_for_shipment with no products for customer" do
      company = ::Company.create!(name: "A Company")
      customer = ::Customer.create!(name: "A Customer", company: company)
      user = ::User.create!(company: company, email: "user@example.com", password: "password", confirmed_at: Time.now)
      sign_in user

      carrier = Carrier.create!(company: company, name: "A Carrier")
      carrier_product_1 = CarrierProduct.create!(company: company, carrier: carrier, name: "Product 1", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_2 = CarrierProduct.create!(company: company, carrier: carrier, name: "Product 2", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      carrier_product_3 = CarrierProduct.create!(company: company, carrier: carrier, name: "Product 3", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

      sender_params = {
        address_line1: "Njalsgade 17A",
        zip_code: "2300",
        city: "København S",
        country_name: "Denmark",
        country_code: "DK",
      }

      recipient_params = {
        address_line1: "Åstvej 1",
        zip_code: "7190",
        city: "Billund",
        country_name: "Denmark",
        country_code: "DK",
      }

      package_dimensions_params = {
        "0" => {
          "amount" => "1",
          "length" => "1000",
          "width" => "100",
          "height" => "10",
          "weight" => "1.5",
        }
      }

      post(
        :get_carrier_products_and_prices_for_shipment,
        format: "json",
        customer_id: customer.id,
        sender: sender_params,
        recipient: recipient_params,
        package_dimensions: package_dimensions_params,
      )

      assert_response :success

      json_response = JSON.parse(response.body)

      assert_equal %Q[<label for="No_carriers_products_match_the_sender__recipient__shipment_type_and_package_dimensions_entered">No carriers products match the sender, recipient, shipment type and package dimensions entered</label>\n], json_response["html"]
      assert_nil json_response["digest"]
      assert_equal false, json_response["should_show_route"]
    end
  end
end

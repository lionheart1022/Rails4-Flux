require "test_helper"

module Customers
  class ShipmentsControllerTest < ActionController::TestCase
    include Devise::TestHelpers

    test "create shipment" do
      company = ::Company.create!(name: "Company")
      customer = ::Customer.create!(name: "Customer", company: company)
      carrier = Carrier.create!(company: company, name: "Carrier")
      carrier_product = CarrierProduct.create!(company: company, carrier: carrier, name: "Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product, is_disabled: false)

      user = ::User.create!(email: "user@example.com", password: "password", confirmed_at: Time.zone.now)
      UserCustomerAccess.create!(user: user, customer: customer, company: company)
      EmailSettings.build_with_all_set(user: user).save!
      sign_in user

      post_params =
        {
          "current_customer_identifier" => customer.id,
          "shipment" => {
            "shipment_type" => "Export",
            "rfq" => "false",
            "sender_attributes" => {
              "company_name" => "Test Customer A",
              "attention" => "Test Person",
              "address_line1" => "Njalsgade 17A",
              "address_line2" => "",
              "address_line3" => "",
              "zip_code" => "2300",
              "city" => "København S",
              "country_code" => "dk",
              "phone_number" => "",
              "email" => "",
              "residential" => "0",
              "save_sender_in_address_book" => "0"
            },
            "recipient_attributes" => {
              "company_name" => "Legoland",
              "attention" => "Legomand",
              "address_line1" => "Nordmarksvej 9",
              "address_line2" => "",
              "address_line3" => "",
              "zip_code" => "7190",
              "city" => "Billund",
              "country_code" => "dk",
              "phone_number" => "",
              "email" => "legoland@example.com",
              "residential" => "0",
              "save_recipient_in_address_book" => "0"
            },
            "package_dimensions" => {
              "0" => {
                "amount" => "1",
                "length" => "10",
                "width" => "20",
                "height" => "30",
                "weight" => "4"
              },
              "1538054617560" => {
                "amount" => "4",
                "length" => "5",
                "width" => "5",
                "height" => "5",
                "weight" => "1"
              }
            },
            "description" => "",
            "reference" => "",
            "remarks" => "",
            "dangerous_goods" => "0",
            "shipping_date(1i)" => "2018",
            "shipping_date(2i)" => "9",
            "shipping_date(3i)" => "27",
            "carrier_product_id" => carrier_product.id,
            "request_pickup" => "1",
            "pickup_options" => {
              "from_time" => "20 =>00",
              "to_time" => "23 =>00",
              "description" => "Warehouse",
              "contact_attributes" => {
                "company_name" => "Test Customer A",
                "attention" => "Test Person",
                "address_line1" => "Njalsgade 17A",
                "address_line2" => "",
                "address_line3" => "",
                "zip_code" => "2300",
                "city" => "København S",
                "country_code" => "dk"
              }
            },
            "dutiable" => "0"
          }
        }

      assert_difference "Shipment.count" do
        post :create, post_params.with_indifferent_access
      end

      assert_response :redirect
    end
  end
end

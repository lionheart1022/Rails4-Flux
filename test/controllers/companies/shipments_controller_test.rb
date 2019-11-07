require "test_helper"

module Companies
  class ShipmentsControllerTest < ActionController::TestCase
    include Devise::TestHelpers

    test "create shipment" do
      company = ::Company.create!(name: "Company")
      customer = company.create_customer!(name: "Customer")
      carrier = Carrier.create!(company: company, name: "Carrier")
      carrier_product = CarrierProduct.create!(company: company, carrier: carrier, name: "Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product, is_disabled: false)

      user = ::User.create!(company: company, email: "user@example.com", password: "password", confirmed_at: Time.zone.now)
      EmailSettings.build_with_all_set(user: user).save!
      sign_in user

      post_params =
        {
          "shipment" => {
            "customer_id" => customer.id,
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
              "1" => {
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
              "from_time" => "20:00",
              "to_time" => "23:00",
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
            "dutiable" => "1",
            "customs_amount" => "10,75",
            "customs_currency" => "DKK",
          }
        }

      assert_difference "Shipment.count" do
        post :create, post_params.with_indifferent_access
      end

      assert_response :redirect

      shipment = Shipment.all.order(id: :desc).last

      assert shipment
      assert_equal Date.new(2018, 9, 27), shipment.shipping_date
      assert_equal BigDecimal("10.75"), shipment.customs_amount

      assert shipment.pickup_relation
      assert_equal "20:00", shipment.pickup_relation.from_time
      assert_equal "23:00", shipment.pickup_relation.to_time
      assert_equal Date.new(2018, 9, 27), shipment.pickup_relation.pickup_date
    end

    test "create shipment and then update it" do
      company = ::Company.create!(name: "Company")
      customer = company.create_customer!(name: "Customer")
      carrier = Carrier.create!(company: company, name: "Carrier")
      carrier_product = CarrierProduct.create!(company: company, carrier: carrier, name: "Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product, is_disabled: false)

      user = ::User.create!(company: company, email: "user@example.com", password: "password", confirmed_at: Time.zone.now)
      EmailSettings.build_with_all_set(user: user).save!
      sign_in user

      post_params =
        {
          "shipment" => {
            "customer_id" => customer.id,
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
              "1" => {
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
              "from_time" => "20:00",
              "to_time" => "23:00",
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
            "dutiable" => "1",
            "customs_amount" => "10,75",
            "customs_currency" => "DKK",
          }
        }

      assert_difference "Shipment.count" do
        post :create, post_params.with_indifferent_access
      end

      assert_response :redirect

      shipment = Shipment.all.order(id: :desc).last

      assert shipment
      assert_equal Date.new(2018, 9, 27), shipment.shipping_date
      assert_equal BigDecimal("10.75"), shipment.customs_amount

      assert shipment.pickup_relation
      assert_equal "20:00", shipment.pickup_relation.from_time
      assert_equal "23:00", shipment.pickup_relation.to_time
      assert_equal Date.new(2018, 9, 27), shipment.pickup_relation.pickup_date

      assert_no_difference "Shipment.count" do
        post :update, id: shipment.id, shipment: {
          :"shipping_date(1i)" => "2018",
          :"shipping_date(2i)" => "11",
          :"shipping_date(3i)" => "20",
          package_dimensions: {
            :"0" => {
              amount: "1",
              length: "10",
              width: "40",
              height: "30",
              weight: "7",
            },
            :"1" => {
              amount: "4",
              length: "5",
              width: "5",
              height: "5",
              weight: "1",
            }
          },
          sender_attributes: {
            company_name: "New Sender Company Name",
          },
          recipient_attributes: {
            company_name: "New Recipient Company Name",
          }
        }
      end

      assert_response :redirect

      shipment.reload
      assert_equal Date.new(2018, 11, 20), shipment.shipping_date
    end

    test "create shipment with truck and driver" do
      company = ::Company.create!(name: "Company")
      customer = company.create_customer!(name: "Customer")
      carrier = Carrier.create!(company: company, name: "Carrier")
      carrier_product = CarrierProduct.create!(company: company, carrier: carrier, name: "Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product, is_disabled: false)

      truck = FactoryBot.create(:truck, company: company)

      user = ::User.create!(company: company, email: "user@example.com", password: "password", confirmed_at: Time.zone.now)
      EmailSettings.build_with_all_set(user: user).save!
      sign_in user

      post_params =
        {
          "shipment" => {
            "customer_id" => customer.id,
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
              "1" => {
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
              "from_time" => "20:00",
              "to_time" => "23:00",
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
            "select_truck_and_driver" => 1,
            "truck_id"=>truck.id,
            "driver_id"=>"",
            "dutiable" => "0"
          }
        }

      assert_difference "Delivery.count" do
        post :create, post_params.with_indifferent_access
      end

      assert_equal Delivery.last.truck, truck

      assert_not truck.reload.active_delivery.nil?

      assert_response :redirect

      shipment = Shipment.all.order(id: :desc).last

      assert shipment
      assert_equal Date.new(2018, 9, 27), shipment.shipping_date

      assert shipment.pickup_relation
      assert_equal "20:00", shipment.pickup_relation.from_time
      assert_equal "23:00", shipment.pickup_relation.to_time
      assert_equal Date.new(2018, 9, 27), shipment.pickup_relation.pickup_date
    end
  end
end

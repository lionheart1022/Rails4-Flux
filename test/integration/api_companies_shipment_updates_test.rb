require "test_helper"

class APICompaniesShipmentUpdatesTest < ActionDispatch::IntegrationTest
  test "updates are processed successfully" do
    current_company = FactoryBot.create(:company)
    product_x = CarrierProduct.create!(name: "Product X", company: current_company, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

    some_other_company = FactoryBot.create(:company)
    product_y = CarrierProduct.create!(name: "Product Y", company: some_other_company, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

    access_token = AccessToken.create!(owner: current_company, value: SecureRandom.hex)

    FactoryBot.create(:shipment, unique_shipment_id: "1-1-1", state: "created", company: current_company, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-2", state: "created", company: current_company, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-3", state: "created", company: some_other_company, carrier_product: product_y, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-4", state: "created", company: current_company, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))

    json_request = JSON.parse(<<-BODY)
      {
        "updates": [
          {
            "shipment_id": "1-1-1",
            "state_change": {
              "new_state": "booked",
              "comment": "",
              "awb": "XXX"
            },
            "upload_label_from_url": "https://www.example.com/label.pdf"
          },
          {
            "shipment_id": "1-1-2",
            "state_change": {
              "new_state": "in_transit",
              "comment": "Picked up by Bob the Driver"
            }
          },
          {
            "shipment_id": "1-1-3",
            "state_change": {
              "new_state": "problem",
              "comment": "Booking error: recipient zip code is invalid"
            }
          },
          {
            "shipment_id": "1-1-4",
            "upload_invoice_from_url": "https://www.example.com/invoice.pdf"
          }
        ]
      }
    BODY

    post(
      "/api/v1/companies/shipment_updates.json",
      { updates: json_request["updates"] },
      { "Access-Token" => access_token.value }
    )

    assert_equal 200, status

    json_response = JSON.parse(response.body)

    assert json_response["shipments"]
    assert_equal 4, json_response["shipments"].count
    assert_equal "booked", json_response["shipments"][0]["state"]
    assert_equal "in_transit", json_response["shipments"][1]["state"]
    assert_nil json_response["shipments"][2]["state"]
    assert_equal "created", json_response["shipments"][3]["state"]
  end

  test "without .json still works as expected" do
    current_company = FactoryBot.create(:company)
    product_x = CarrierProduct.create!(name: "Product X", company: current_company, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

    access_token = AccessToken.create!(owner: current_company, value: SecureRandom.hex)

    FactoryBot.create(:shipment, unique_shipment_id: "1-1-1", state: "created", company: current_company, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-2", state: "created", company: current_company, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))

    json_request = JSON.parse(<<-BODY)
      {
        "updates": [
          {
            "shipment_id": "1-1-1",
            "state_change": {
              "new_state": "booked",
              "comment": "",
              "awb": "XXX"
            },
            "upload_label_from_url": "https://www.example.com/label.pdf"
          },
          {
            "shipment_id": "1-1-2",
            "state_change": {
              "new_state": "in_transit",
              "comment": "Picked up by Bob the Driver"
            }
          }
        ]
      }
    BODY

    post(
      "/api/v1/companies/shipment_updates",
      { updates: json_request["updates"] },
      { "Access-Token" => access_token.value }
    )

    assert_equal 200, status

    json_response = JSON.parse(response.body)

    assert json_response["shipments"]
    assert_equal 2, json_response["shipments"].count
    assert_equal "booked", json_response["shipments"][0]["state"]
    assert_equal "in_transit", json_response["shipments"][1]["state"]
  end

  test "no 'updates'-key fails" do
    current_company = FactoryBot.create(:company)

    access_token = AccessToken.create!(owner: current_company, value: SecureRandom.hex)

    post(
      "/api/v1/companies/shipment_updates.json",
      {},
      { "Access-Token" => access_token.value }
    )

    assert_equal 400, status

    json_response = JSON.parse(response.body)
    assert json_response["error"]
  end

  test "too many updates causes failure" do
    current_company = FactoryBot.create(:company)

    access_token = AccessToken.create!(owner: current_company, value: SecureRandom.hex)

    post(
      "/api/v1/companies/shipment_updates.json",
      { updates: 101.times.map { { shipment_id: "1-1-1" } } }, # The default max number of updates is 100.
      { "Access-Token" => access_token.value }
    )

    assert_equal 400, status

    json_response = JSON.parse(response.body)
    assert json_response["error"]
  end
end

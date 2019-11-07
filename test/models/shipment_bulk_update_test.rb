require "test_helper"

class ShipmentBulkUpdateTest < ActiveSupport::TestCase
  test "update is parsed for updating state" do
    current_company = Company.new
    payload = build_payload(<<-BODY)
      {
        "updates": [
          {
            "shipment_id": "1-1-1",
            "state_change": { "new_state": "booked", "comment": "", "awb": "XXX" },
            "upload_label_from_url": "https://www.example.com/label.pdf"
          }
        ]
      }
    BODY

    bulk_update = ShipmentBulkUpdate.new(current_company: current_company, payload: payload)
    operation = bulk_update.operations[0]

    assert operation
    assert_equal "1-1-1", operation.shipment_id
    assert operation.update_state?
  end

  test "update is parsed for uploading asset" do
    current_company = Company.new
    payload = build_payload(<<-BODY)
      {
        "updates": [
          {
            "shipment_id": "1-1-1",
            "state_change": { "new_state": "booked", "comment": "", "awb": "XXX" },
            "upload_label_from_url": "https://www.example.com/label.pdf"
          }
        ]
      }
    BODY

    bulk_update = ShipmentBulkUpdate.new(current_company: current_company, payload: payload)
    operation = bulk_update.operations[0]

    assert operation
    assert_equal "1-1-1", operation.shipment_id
    assert operation.upload_assets?
  end

  test "performing multiple updates related to state" do
    current_company = FactoryBot.create(:company)
    product_x = CarrierProduct.create!(name: "Product X", company: current_company, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

    some_other_company = FactoryBot.create(:company)
    product_y = CarrierProduct.create!(name: "Product Y", company: some_other_company, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

    FactoryBot.create(:shipment, unique_shipment_id: "1-1-1", state: "created", company: current_company, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-2", state: "created", company: current_company, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-3", state: "created", company: some_other_company, carrier_product: product_y, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-4", state: "created", company: current_company, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))

    payload = build_payload(<<-BODY)
      {
        "updates": [
          {
            "shipment_id": "1-1-1",
            "state_change": { "new_state": "booked", "comment": "", "awb": "XXX" }
          },
          {
            "shipment_id": "1-1-2",
            "state_change": { "new_state": "in_transit", "comment": "Picked up by Bob the Driver" }
          },
          {
            "shipment_id": "1-1-3",
            "state_change": { "new_state": "problem", "comment": "Booking error: recipient zip code is invalid" }
          },
          {
            "shipment_id": "1-1-4"
          }
        ]
      }
    BODY

    bulk_update = ShipmentBulkUpdate.new(current_company: current_company, payload: payload)

    assert_equal 4, bulk_update.operations.count

    result = bulk_update.perform!

    assert result
    assert_equal 4, result.shipments.count
    assert_equal "booked", result.shipments[0][:state]
    assert_equal "in_transit", result.shipments[1][:state]
    assert_nil result.shipments[2][:state]
    assert_equal "created", result.shipments[3][:state]
  end

  test "performing multiple updates related to asset uploads" do
    current_company = FactoryBot.create(:company)
    product_x = CarrierProduct.create!(name: "Product X", company: current_company, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

    some_other_company = FactoryBot.create(:company)
    product_y = CarrierProduct.create!(name: "Product Y", company: some_other_company, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

    FactoryBot.create(:shipment, unique_shipment_id: "1-1-1", state: "booked", company: current_company, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-2", state: "created", company: current_company, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-3", state: "booked", company: some_other_company, carrier_product: product_y, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-4", state: "created", company: current_company, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))

    payload = build_payload(<<-BODY)
      {
        "updates": [
          {
            "shipment_id": "1-1-1",
            "upload_label_from_url": "https://www.example.com/label-1.pdf"
          },
          {
            "shipment_id": "1-1-2"
          },
          {
            "shipment_id": "1-1-3",
            "upload_label_from_url": "https://www.example.com/label-3.pdf"
          },
          {
            "shipment_id": "1-1-4",
            "upload_invoice_from_url": "https://www.example.com/invoice.pdf"
          }
        ]
      }
    BODY

    bulk_update = ShipmentBulkUpdate.new(current_company: current_company, payload: payload)

    assert_equal 4, bulk_update.operations.count

    result = bulk_update.perform!

    assert result
    assert_equal 4, result.shipments.count
    assert_equal 4, result.shipment_assets.count

    assert_equal({ "awb" => "https://www.example.com/label-1.pdf" }, result.shipment_assets[0][:asset_urls_to_upload])
    assert_equal({}, result.shipment_assets[1][:asset_urls_to_upload])
    assert_nil result.shipment_assets[2][:asset_urls_to_upload]
    assert_equal({ "invoice" => "https://www.example.com/invoice.pdf" }, result.shipment_assets[3][:asset_urls_to_upload])
  end

  test "only performs updates to products owned by current company" do
    current_company = FactoryBot.create(:company)
    customer = FactoryBot.create(:customer, company: current_company)
    product_x = CarrierProduct.create!(name: "Product X", company: current_company, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

    another_company = FactoryBot.create(:company)
    another_customer = FactoryBot.create(:customer, company: another_company)
    another_product_x = CarrierProduct.create!(carrier_product: product_x, company: another_company, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)

    some_other_company = FactoryBot.create(:company)
    product_y = CarrierProduct.create!(name: "Product Y", company: some_other_company, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
    product_y_for_current_company = CarrierProduct.create!(carrier_product: product_y, company: current_company, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)

    FactoryBot.create(:shipment, unique_shipment_id: "1-1-1", state: "created", company: current_company, customer: customer, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-2", state: "created", company: another_company, customer: another_customer, carrier_product: another_product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-3", state: "created", company: current_company, customer: customer, carrier_product: product_y_for_current_company, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    FactoryBot.create(:shipment, unique_shipment_id: "1-1-4", state: "created", company: current_company, customer: customer, carrier_product: product_x, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))

    payload = build_payload(<<-BODY)
      {
        "updates": [
          {
            "shipment_id": "1-1-1",
            "state_change": { "new_state": "booked", "comment": "", "awb": "XXX" }
          },
          {
            "shipment_id": "1-1-2",
            "state_change": { "new_state": "in_transit", "comment": "Picked up by Bob the Driver" }
          },
          {
            "shipment_id": "1-1-3",
            "state_change": { "new_state": "problem", "comment": "Booking error: recipient zip code is invalid" }
          },
          {
            "shipment_id": "1-1-4"
          }
        ]
      }
    BODY

    bulk_update = ShipmentBulkUpdate.new(current_company: current_company, payload: payload)

    assert_equal 4, bulk_update.operations.count

    result = bulk_update.perform!

    assert result
    assert_equal 4, result.shipments.count
    assert_equal "booked", result.shipments[0][:state]
    assert_equal "in_transit", result.shipments[1][:state]
    assert_equal "created", result.shipments[2][:state]
    assert_equal "created", result.shipments[3][:state]
  end

  test "failure when 'updates' key is missing" do
    current_company = Company.new
    payload = build_payload(<<-BODY)
      {
        "some_updates": []
      }
    BODY

    assert_raises ShipmentBulkUpdate::MissingRequiredParam do
      bulk_update = ShipmentBulkUpdate.new(current_company: current_company, payload: payload)
    end
  end

  test "failure when max number of updates is exceeded" do
    current_company = Company.new
    payload = build_payload(<<-BODY)
      {
        "updates": [
          {
            "shipment_id": "1-1-1",
            "state_change": { "new_state": "booked", "comment": "", "awb": "XXX" }
          },
          {
            "shipment_id": "1-1-2",
            "state_change": { "new_state": "in_transit", "comment": "Picked up by Bob the Driver" }
          },
          {
            "shipment_id": "1-1-3",
            "state_change": { "new_state": "problem", "comment": "Booking error: recipient zip code is invalid" }
          },
          {
            "shipment_id": "1-1-4"
          }
        ]
      }
    BODY

    assert_raises ShipmentBulkUpdate::ExceededMaximumUpdates do
      bulk_update = ShipmentBulkUpdate.new(current_company: current_company, payload: payload, max_number_of_updates: 3)
    end
  end

  private

  def build_payload(json_body)
    payload = ActionController::Parameters.new(JSON.parse(json_body))

    payload.permit(
      :updates => [
        :shipment_id,
        :upload_label_from_url,
        :upload_invoice_from_url,
        :upload_consignment_note_from_url,
        :state_change => [:new_state, :comment, :awb],
      ]
    )
  end
end

require "test_helper"

class APICompaniesShipmentExportsTest < ActionDispatch::IntegrationTest
  test "new shipments are exported as not already exported" do
    company = Company.create!(name: "Company")
    access_token = AccessToken.create!(owner: company, value: SecureRandom.hex)
    shipment_export_setting = ShipmentExportSetting.create!(owner: company, booked: false, in_transit: false, delivered: false, problem: false, trigger_when_created: true, trigger_when_cancelled: false)
    carrier = Carrier.create!(name: "Carrier", company: company)
    carrier_product = CarrierProduct.create!(name: "Carrier product", carrier: carrier, company: company)
    shipment_1 = FactoryBot.create(:shipment, unique_shipment_id: "1", sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient), company: company, carrier_product: carrier_product)
    shipment_2 = FactoryBot.create(:shipment, unique_shipment_id: "2", sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    shipment_3 = FactoryBot.create(:shipment, unique_shipment_id: "3", sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient), company: company, carrier_product: carrier_product)

    event = Shipment::Events::CREATE

    ShipmentExportManager.handle_event(event: event, event_arguments: { shipment_id: shipment_1.id })
    ShipmentExportManager.handle_event(event: event, event_arguments: { shipment_id: shipment_2.id })
    ShipmentExportManager.handle_event(event: event, event_arguments: { shipment_id: shipment_3.id })

    post "/api/v1/companies/shipment_exports.xml", access_token: access_token.value
    assert_equal 200, status

    doc = Nokogiri::XML(response.body)

    assert_equal Set.new([shipment_1.unique_shipment_id, shipment_3.unique_shipment_id]), Set.new(doc.xpath("//NewShipments/Shipment/ShipmentId").map(&:text))
    assert_equal 0, doc.xpath("//UpdatedShipments/Shipment").count
  end

  test "new shipments which haven't been export are exported as not already exported" do
    company = Company.create!(name: "Company")
    access_token = AccessToken.create!(owner: company, value: SecureRandom.hex)
    shipment_export_setting = ShipmentExportSetting.create!(owner: company, booked: true, in_transit: false, delivered: false, problem: false, trigger_when_created: true, trigger_when_cancelled: false)
    carrier = Carrier.create!(name: "Carrier", company: company)
    carrier_product = CarrierProduct.create!(name: "Carrier product", carrier: carrier, company: company)
    shipment_1 = FactoryBot.create(:shipment, unique_shipment_id: "1", sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient), company: company, carrier_product: carrier_product)
    shipment_2 = FactoryBot.create(:shipment, unique_shipment_id: "2", sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    shipment_3 = FactoryBot.create(:shipment, unique_shipment_id: "3", sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient), company: company, carrier_product: carrier_product)

    # Shipments are created
    ShipmentExportManager.handle_event(event: Shipment::Events::CREATE, event_arguments: { shipment_id: shipment_1.id })
    ShipmentExportManager.handle_event(event: Shipment::Events::CREATE, event_arguments: { shipment_id: shipment_2.id })
    ShipmentExportManager.handle_event(event: Shipment::Events::CREATE, event_arguments: { shipment_id: shipment_3.id })

    # Shipment gets booked before export
    ShipmentExportManager.handle_event(event: Shipment::Events::BOOK, event_arguments: { shipment_id: shipment_3.id })

    post "/api/v1/companies/shipment_exports.xml", access_token: access_token.value
    assert_equal 200, status

    doc = Nokogiri::XML(response.body)

    assert_equal Set.new([shipment_1.unique_shipment_id, shipment_3.unique_shipment_id]), Set.new(doc.xpath("//NewShipments/Shipment/ShipmentId").map(&:text))
    assert_equal 0, doc.xpath("//UpdatedShipments/Shipment").count
  end

  test "shipments which have already been exported are exported as updated" do
    company = Company.create!(name: "Company")
    access_token = AccessToken.create!(owner: company, value: SecureRandom.hex)
    shipment_export_setting = ShipmentExportSetting.create!(owner: company, booked: true, in_transit: false, delivered: false, problem: false, trigger_when_created: true, trigger_when_cancelled: false)
    carrier = Carrier.create!(name: "Carrier", company: company)
    carrier_product = CarrierProduct.create!(name: "Carrier product", carrier: carrier, company: company)
    shipment_1 = FactoryBot.create(:shipment, unique_shipment_id: "1", sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient), company: company, carrier_product: carrier_product)
    shipment_2 = FactoryBot.create(:shipment, unique_shipment_id: "2", sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))
    shipment_3 = FactoryBot.create(:shipment, unique_shipment_id: "3", sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient), company: company, carrier_product: carrier_product)

    # Shipments are created
    ShipmentExportManager.handle_event(event: Shipment::Events::CREATE, event_arguments: { shipment_id: shipment_1.id })
    ShipmentExportManager.handle_event(event: Shipment::Events::CREATE, event_arguments: { shipment_id: shipment_2.id })
    ShipmentExportManager.handle_event(event: Shipment::Events::CREATE, event_arguments: { shipment_id: shipment_3.id })

    # First time
    post "/api/v1/companies/shipment_exports.xml", access_token: access_token.value
    assert_equal 200, status

    doc = Nokogiri::XML(response.body)

    assert_equal Set.new([shipment_1.unique_shipment_id, shipment_3.unique_shipment_id]), Set.new(doc.xpath("//NewShipments/Shipment/ShipmentId").map(&:text))
    assert_equal 0, doc.xpath("//UpdatedShipments/Shipment").count

    # This will mark shipment as updated
    ShipmentExportManager.handle_event(event: Shipment::Events::BOOK, event_arguments: { shipment_id: shipment_3.id })

    # Second time
    post "/api/v1/companies/shipment_exports.xml", access_token: access_token.value
    assert_equal 200, status

    doc = Nokogiri::XML(response.body)

    assert_equal 0, doc.xpath("//NewShipments/Shipment/ShipmentId").count
    assert_equal 1, doc.xpath("//UpdatedShipments/Shipment").count
  end
end

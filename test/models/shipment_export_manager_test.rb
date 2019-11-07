require "test_helper"

class ShipmentExportManagerTest < ActiveSupport::TestCase
  test "new shipments are exported as not already exported" do
    company = Company.create!(name: "Company")
    shipment_export_setting = ShipmentExportSetting.create!(owner: company, booked: false, in_transit: false, delivered: false, problem: false, trigger_when_created: true, trigger_when_cancelled: false)
    carrier = Carrier.create!(name: "Carrier", company: company)
    carrier_product = CarrierProduct.create!(name: "Carrier product", carrier: carrier, company: company)
    shipment_1 = FactoryBot.create(:shipment, company: company, carrier_product: carrier_product)
    shipment_2 = FactoryBot.create(:shipment)
    shipment_3 = FactoryBot.create(:shipment, company: company, carrier_product: carrier_product)

    event = Shipment::Events::CREATE

    ShipmentExportManager.handle_event(event: event, event_arguments: { shipment_id: shipment_1.id })
    ShipmentExportManager.handle_event(event: event, event_arguments: { shipment_id: shipment_2.id })
    ShipmentExportManager.handle_event(event: event, event_arguments: { shipment_id: shipment_3.id })

    interactor = Companies::ShipmentExports::Export.new(company_id: company.id)

    assert_equal Set.new([shipment_1.id, shipment_3.id]), Set.new(interactor.send(:find_not_exported).map(&:id))
    assert_equal 0, interactor.send(:find_updated).size
  end

  test "new shipments which haven't been export are exported as not already exported" do
    company = Company.create!(name: "Company")
    shipment_export_setting = ShipmentExportSetting.create!(owner: company, booked: true, in_transit: false, delivered: false, problem: false, trigger_when_created: true, trigger_when_cancelled: false)
    carrier = Carrier.create!(name: "Carrier", company: company)
    carrier_product = CarrierProduct.create!(name: "Carrier product", carrier: carrier, company: company)
    shipment_1 = FactoryBot.create(:shipment, company: company, carrier_product: carrier_product)
    shipment_2 = FactoryBot.create(:shipment)
    shipment_3 = FactoryBot.create(:shipment, company: company, carrier_product: carrier_product)

    # Shipments are created
    ShipmentExportManager.handle_event(event: Shipment::Events::CREATE, event_arguments: { shipment_id: shipment_1.id })
    ShipmentExportManager.handle_event(event: Shipment::Events::CREATE, event_arguments: { shipment_id: shipment_2.id })
    ShipmentExportManager.handle_event(event: Shipment::Events::CREATE, event_arguments: { shipment_id: shipment_3.id })

    # Shipment gets booked before export
    ShipmentExportManager.handle_event(event: Shipment::Events::BOOK, event_arguments: { shipment_id: shipment_3.id })

    interactor = Companies::ShipmentExports::Export.new(company_id: company.id)

    assert_equal Set.new([shipment_1.id, shipment_3.id]), Set.new(interactor.send(:find_not_exported).map(&:id))
    assert_equal 0, interactor.send(:find_updated).size
  end
end

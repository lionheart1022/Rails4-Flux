require "test_helper"

class ShipmentTest < ActiveSupport::TestCase
  test "#update_state when changing from PROBLEM to CANCELLED" do
    shipment = FactoryBot.create(:shipment)
    shipment.update_attributes(state: Shipment::States::PROBLEM, shipment_errors: [StandardError.new])
    shipment.send(:update_state, { new_state: Shipment::States::CANCELLED })

    refute shipment.shipment_errors.empty?
  end

  test "#update_state when changing from CANCELLED to any state not PROBLEM" do
    shipment = FactoryBot.create(:shipment)
    shipment.update_attributes(state: Shipment::States::PROBLEM, shipment_errors: [StandardError.new])
    shipment.send(:update_state, { new_state: Shipment::States::BOOKED })

    assert shipment.shipment_errors.empty?
  end

  test "setting additional_surcharges should delete previous records" do
    shipment = FactoryBot.create(:shipment)
    shipment.additional_surcharges = [ShipmentAdditionalSurcharge.new, ShipmentAdditionalSurcharge.new]

    shipment.reload
    assert_equal 2, shipment.additional_surcharges.count

    assert_nothing_raised do
      shipment.additional_surcharges = [ShipmentAdditionalSurcharge.new]
    end

    shipment.reload
    assert_equal 1, shipment.additional_surcharges.count
  end
end

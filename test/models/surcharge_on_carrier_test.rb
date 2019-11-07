require "test_helper"

class SurchargeOnCarrierTest < ActiveSupport::TestCase
  test "#active_surcharge for regular surcharge" do
    carrier = FactoryBot.create(:carrier)
    surcharge_on_carrier = SurchargeOnCarrier.create!(
      carrier: carrier,
      surcharge: Surcharge.new(description: "Fuel", charge_value: "13", calculation_method: "price_percentage"),
    )

    active_surcharge = surcharge_on_carrier.active_surcharge
    assert active_surcharge
    assert_equal "13 %", active_surcharge.formatted_value
  end

  test "#active_surcharge for monthly surcharge" do
    first_day_this_month = Time.zone.now.beginning_of_month
    carrier = FactoryBot.create(:carrier)
    surcharge_on_carrier = SurchargeOnCarrier.create!(carrier: carrier, surcharge: FuelSurcharge.new)
    SurchargeWithExpiration.create!(owner: surcharge_on_carrier, valid_from: first_day_this_month, expires_on: first_day_this_month.end_of_month, surcharge: FuelSurcharge.new(description: "Fuel", charge_value: "7", calculation_method: "price_percentage"))

    active_surcharge = surcharge_on_carrier.active_surcharge
    assert active_surcharge
    assert_equal "7 %", active_surcharge.formatted_value
  end

  test "#active_surcharge for monthly surcharge with missing value for this month" do
    first_day_this_month = Time.zone.now.beginning_of_month
    first_day_last_month = first_day_this_month.advance(months: -1)
    carrier = FactoryBot.create(:carrier)
    surcharge_on_carrier = SurchargeOnCarrier.create!(carrier: carrier, surcharge: FuelSurcharge.new)
    SurchargeWithExpiration.create!(owner: surcharge_on_carrier, valid_from: first_day_last_month, expires_on: first_day_last_month.end_of_month, surcharge: FuelSurcharge.new(description: "Fuel", charge_value: "3", calculation_method: "price_percentage"))

    active_surcharge = surcharge_on_carrier.active_surcharge
    assert active_surcharge
    assert_equal "3 %", active_surcharge.formatted_value
  end
end

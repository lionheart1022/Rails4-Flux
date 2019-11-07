require "test_helper"

class CarrierProductRuleTest < ActiveSupport::TestCase
  test "all criteria should be met" do
    rule = CarrierProductRule.new
    rule.shipment_weight_interval.attributes = { enabled: true, to: "20.0", to_inclusive: false }
    rule.number_of_packages_interval.attributes = { enabled: true, from: "5", from_inclusive: true }

    assert rule.match?(shipment_weight: BigDecimal("10.0"), number_of_packages: 7, recipient_country_code: nil)
    refute rule.match?(shipment_weight: BigDecimal("10.0"), number_of_packages: 4, recipient_country_code: nil)
  end

  test "comma in shipment weight is handled" do
    rule = CarrierProductRule.new
    rule.shipment_weight_interval.attributes = { enabled: true, to: "0,5", to_inclusive: true }

    assert rule.match?(shipment_weight: BigDecimal("0.4"), number_of_packages: nil, recipient_country_code: nil)
    assert rule.match?(shipment_weight: BigDecimal("0.5"), number_of_packages: nil, recipient_country_code: nil)
    refute rule.match?(shipment_weight: BigDecimal("0.51"), number_of_packages: nil, recipient_country_code: nil)
  end

  test "no criteria will always match" do
    rule = CarrierProductRule.new

    assert rule.match?(shipment_weight: nil, number_of_packages: nil, recipient_country_code: nil)
  end
end

require "test_helper"

class CarrierProductSurchargeTest < ActiveSupport::TestCase
  test "#surcharges_to_apply with only carrier-level surcharges" do
    carrier = Carrier.create!(name: "My Carrier")
    carrier_product = CarrierProduct.create!(name: "My Carrier Product", carrier: carrier)

    surcharge_1 = FuelSurcharge.create!(description: "Fuel", calculation_method: "price_percentage", charge_value: "15")
    SurchargeOnCarrier.create!(carrier: carrier, surcharge: surcharge_1)

    surcharge_2 = Surcharge.create!(description: "Some other fee", calculation_method: "price_fixed", charge_value: "100")
    SurchargeOnCarrier.create!(carrier: carrier, surcharge: surcharge_2)

    assert_equal [surcharge_1, surcharge_2], carrier_product.surcharges_to_apply
  end

  test "#surcharges_to_apply with a mix of carrier and product-level surcharges" do
    carrier = Carrier.create!(name: "My Carrier")
    carrier_product = CarrierProduct.create!(name: "My Carrier Product", carrier: carrier)

    surcharge_1 = FuelSurcharge.create!(description: "Fuel", calculation_method: "price_percentage", charge_value: "15")
    surcharge_on_carrier_1 = SurchargeOnCarrier.create!(carrier: carrier, surcharge: surcharge_1)

    surcharge_2 = Surcharge.create!(description: "Some other fee", calculation_method: "price_fixed", charge_value: "100")
    surcharge_on_carrier_2 = SurchargeOnCarrier.create!(carrier: carrier, surcharge: surcharge_2)

    # Override surcharge on product-level
    surcharge_3 = Surcharge.create!(description: "Some other fee", calculation_method: "price_fixed", charge_value: "200")
    SurchargeOnProduct.create!(carrier_product: carrier_product, parent: surcharge_on_carrier_2, surcharge: surcharge_3)

    assert_equal [surcharge_1, surcharge_3], carrier_product.surcharges_to_apply
  end

  test "#surcharges_to_apply with a mix of carrier and product-level surcharges where some product-level surcharges are disabled" do
    carrier = Carrier.create!(name: "My Carrier")
    carrier_product = CarrierProduct.create!(name: "My Carrier Product", carrier: carrier)

    surcharge_1 = FuelSurcharge.create!(description: "Fuel", calculation_method: "price_percentage", charge_value: "15")
    surcharge_on_carrier_1 = SurchargeOnCarrier.create!(carrier: carrier, surcharge: surcharge_1)

    surcharge_2 = Surcharge.create!(description: "Some other fee", calculation_method: "price_fixed", charge_value: "100")
    surcharge_on_carrier_2 = SurchargeOnCarrier.create!(carrier: carrier, surcharge: surcharge_2)

    # Override surcharge on product-level
    surcharge_3 = Surcharge.create!(description: "Some other fee", calculation_method: "price_fixed", charge_value: "200")
    SurchargeOnProduct.create!(carrier_product: carrier_product, parent: surcharge_on_carrier_2, surcharge: surcharge_3, enabled: false)

    assert_equal [surcharge_1], carrier_product.surcharges_to_apply
  end

  test "#surcharges_to_apply with a mix of carrier and product-level surcharges where some carrier-level surcharges are disabled" do
    carrier = Carrier.create!(name: "My Carrier")
    carrier_product = CarrierProduct.create!(name: "My Carrier Product", carrier: carrier)

    surcharge_1 = FuelSurcharge.create!(description: "Fuel", calculation_method: "price_percentage", charge_value: "15")
    surcharge_on_carrier_1 = SurchargeOnCarrier.create!(carrier: carrier, surcharge: surcharge_1)

    surcharge_2 = Surcharge.create!(description: "Some other fee", calculation_method: "price_fixed", charge_value: "100")
    surcharge_on_carrier_2 = SurchargeOnCarrier.create!(carrier: carrier, surcharge: surcharge_2, enabled: false)

    # Override surcharge on product-level
    surcharge_3 = Surcharge.create!(description: "Some other fee", calculation_method: "price_fixed", charge_value: "200")
    SurchargeOnProduct.create!(carrier_product: carrier_product, parent: surcharge_on_carrier_2, surcharge: surcharge_3)

    assert_equal [surcharge_1], carrier_product.surcharges_to_apply
  end
end

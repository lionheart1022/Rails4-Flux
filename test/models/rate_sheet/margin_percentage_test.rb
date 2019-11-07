require "test_helper"

class RateSheetMarginPercentageTest < ActiveSupport::TestCase
  test "building 1-level margin" do
    carrier_product = CarrierProduct.new
    carrier_product.build_carrier_product_price(price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

    customer_carrier_product = CustomerCarrierProduct.new
    customer_carrier_product.build_sales_price(margin_percentage: "10.00")

    rate_sheet = RateSheet.new(carrier_product: carrier_product)
    rate_sheet.build_1_level_margin(customer_carrier_product: customer_carrier_product)

    assert rate_sheet.margins.present?
    assert_equal "1-level", rate_sheet.margins["method"]
    assert_equal customer_carrier_product.sales_price.margin_percentage, rate_sheet.margins["value"]
    assert_equal "percentage", rate_sheet.margins["value_type"]
  end

  test "building snapshot" do
    carrier_product = CarrierProduct.new
    carrier_product.build_carrier_product_price(price_document: TestPriceDocuments.price_single_1kg_single_zone_dk)

    customer_carrier_product = CustomerCarrierProduct.new
    customer_carrier_product.build_sales_price(margin_percentage: "10.00")

    rate_sheet = RateSheet.new(carrier_product: carrier_product)
    rate_sheet.build_1_level_margin(customer_carrier_product: customer_carrier_product)
    rate_sheet.build_rate_snapshot

    rate_snapshot = rate_sheet.rate_snapshot

    assert rate_snapshot.present?
    assert_equal "v2", rate_snapshot["version"]
    assert_equal "DKK", rate_snapshot["currency"]
    assert_equal 1, rate_snapshot["grouped_zones"].length
    assert_equal 1, rate_snapshot["grouped_zones"].first.length
    assert_equal 1, rate_snapshot["prices_per_zone_groups"].length
    assert rate_snapshot["prices_per_zone_groups"].first["zones"].present?
    assert rate_snapshot["prices_per_zone_groups"].first["prices"].present?
    assert_equal 2, rate_snapshot["prices_per_zone_groups"].first["prices"].length
    assert_equal "99.00", rate_snapshot["prices_per_zone_groups"].first["prices"][0]["zone_prices"][0]["amount"]
    assert_equal "110.00", rate_snapshot["prices_per_zone_groups"].first["prices"][1]["zone_prices"][0]["amount"]
  end
end

require "test_helper"

class PalletPriceTest < ActiveSupport::TestCase
  def price_document
    TestPriceDocuments.freja_dk_pallet
  end

  test "no parsing errors" do
    assert_equal 0, price_document.parsing_errors.select { |pe| pe.severity ==  PriceDocumentV1::ParseError::Severity::FATAL }.count
  end

  test "price of single pallet" do
    price_calculations = price_document.calculate_price_for_shipment(
      recipient_country_code:  'dk',
      recipient_zip_code: '7600',
      package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)])
    )

    result   = price_calculations.total
    expected = 360 + (0.28 * 360)

    assert_in_error_margin_delta(expected, result)
  end

  test "price of multiple pallets" do
    price_calculations = price_document.calculate_price_for_shipment(
      recipient_country_code:  'dk',
      recipient_zip_code: '4201',
      package_dimensions: PackageDimensions.new(dimensions:[
        PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5),
        PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 12),
        PackageDimension.new(length: 5, width: 52, height: 5, weight: 5, volume_weight: 115)
        ]
      )
    )

    result = price_calculations.total
    expected = (3 * 178) + (0.28 * 3 * 178)

    assert_in_error_margin_delta(expected, result)
  end

  test "price of quarter-pallet when not present in price document" do
    price_calculations = price_document.calculate_price_for_shipment(
      recipient_country_code:  'dk',
      recipient_zip_code: '7600',
      package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 60, width: 40, height: 5, weight: 5, volume_weight: 5)])
    )

    assert_equal BigDecimal("460.80"), price_calculations.total
  end

  test "price of half-pallet when not present in price document" do
    price_calculations = price_document.calculate_price_for_shipment(
      recipient_country_code:  'dk',
      recipient_zip_code: '7600',
      package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 80, width: 60, height: 5, weight: 5, volume_weight: 5)])
    )

    assert_equal BigDecimal("460.80"), price_calculations.total
  end

  test "price of too many pallets" do
    dimensions = (1..40).map do
      PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)
    end

    price_calculations = price_document.calculate_price_for_shipment(
      recipient_country_code:  'dk',
      recipient_zip_code: '7600',
      package_dimensions: PackageDimensions.new(dimensions: dimensions)
    )

    assert_equal false, price_calculations
  end

  test "weight doesnt affect price" do
    total_1 = price_document.calculate_price_for_shipment(
      recipient_country_code:  'dk',
      recipient_zip_code: '7600',
      package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)])
    ).total

    total_2 = price_document.calculate_price_for_shipment(
      recipient_country_code:  'dk',
      recipient_zip_code: '7600',
      package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 35, volume_weight: 5)])
    ).total

    assert total_1 == total_2
  end
end

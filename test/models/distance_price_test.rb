require 'test_helper'

class DistancePriceTest < ActiveSupport::TestCase

   # Filenames
  FILENAME = 'test/price_documents/distance_pricing_test.xlsx'

  test "Freja DK" do

    # Parsing
    price_document = parser.parse(price_document_class: PriceDocumentV1, filename: FILENAME)
    no_parsing_errors = select_fatal_errors(parsing_errors: price_document.parsing_errors).empty?

    assert no_parsing_errors

    #
    # Price Calculation
    #

    # Price below minimum
    price_calculations = price_document.calculate_price_for_shipment(
      recipient_country_code:  'dk',
      recipient_zip_code: '7600',
      package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)]),
      distance_in_kilometers: 10
    )

    result   = price_calculations.total
    expected = 150 + (0.2 * 150) + 50

    assert_in_error_margin_delta(expected, result)

    # Price over maxiumum
    price_calculations = price_document.calculate_price_for_shipment(
      recipient_country_code:  'dk',
      recipient_zip_code: '7600',
      package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)]),
      distance_in_kilometers: 1000
    )

    result   = price_calculations.total
    expected = 5000 + (0.2 * 5000) + 50

    assert_in_error_margin_delta(expected, result)

    # In between
    price_calculations = price_document.calculate_price_for_shipment(
      recipient_country_code:  'dk',
      recipient_zip_code: '7600',
      package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)]),
      distance_in_kilometers: 30
    )

    result   = price_calculations.total
    expected = 300 + (0.2 * 300) + 50

    assert_in_error_margin_delta(expected, result)

  end


end

require 'test_helper'

class TNTDomesticPriceTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/tnt_domestic_final.xlsx'

	test "TNT Domestic" do

		# Parsing
		price_document = parser.parse(price_document_class: TNTPriceDocument, filename: FILENAME)
		no_parsing_errors = select_fatal_errors(parsing_errors: price_document.parsing_errors).empty?

		assert no_parsing_errors

		#
		# Price Calculation
		#

		# Price single
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			recipient_zip_code:      '3400',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 93.01 + 93.01 * 0.2 + [3.75, [75, 30*0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# Price single / calculation basis (shipment)
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			recipient_zip_code:      '3400',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 3, volume_weight: 1),
																														PackageDimension.new(length: 5, width: 5, height: 5, weight: 2, volume_weight: 1)])
		)

		result   = price_calculations.total
		expected = 93.01 + 93.01 * 0.2 + [3.75, [75, 30*0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# Rounding up
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			recipient_zip_code:      '3400',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 39.1, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 103.72 + (0.2 * 103.72) + [3.75, [75, 40*0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# Weight range
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			recipient_zip_code:      '3400',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 73, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 141 + (3 * 1.19) + (141 + 3 * 1.19)*0.2 + [3.75, [75, 73*0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# Weight range round up
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			recipient_zip_code:      '3400',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 72.2, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 141 + (3 * 1.19) + (141 + 3 * 1.19)*0.2 + [3.75, [75, 73*0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# Price single between 2 weight ranges
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			recipient_zip_code:      '3400',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 200, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 295.7 + 295.7*0.2 + [3.75, [75, 200*0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# Out of weight range / volume weight
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			recipient_zip_code:      '3400',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 200, volume_weight: 501)])
		)

		result   = price_calculations
		expected = false

		assert expected == result, "result: #{result}, expected: #{expected}"

		# No matching zone
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'de',
			recipient_zip_code:      '34000',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 20, volume_weight: 1)])
		)

		result   = price_calculations
		expected = false

		assert expected == result, "result: #{result}, expected: #{expected}"

	end


end

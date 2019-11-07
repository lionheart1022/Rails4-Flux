require 'test_helper'

class TNTExpressPriceDocumentTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/tnt_express_final.xlsx'

	test "TNT Expresss" do

		# Parsing
		price_document = parser.parse(price_document_class: TNTPriceDocument, filename: FILENAME)
		no_parsing_errors = select_fatal_errors(parsing_errors: price_document.parsing_errors).empty?

		assert no_parsing_errors

		#
		# Price Calculation
		#

		# Price single
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'lv',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 219.81 + 219.81 * 0.2 + [3.75, [75, 5*0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# Rounding up
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'lv',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 19.1, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 579.91 + (579.91 * 0.2) + [3.75, [75, 20*0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# Zone based fixed charge
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'bo',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 10, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 766.61 + 766.61 * 0.2 + [3.75, [75, 10*0.37].min].max + 58.9

		assert_in_error_margin_delta(expected, result)

		# Weight range round up from price single
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'no',
			recipient_zip_code:      '3400',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 70.1, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 1079.13 + 1079.13 * 0.2 + [3.75, [75, 71*0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# Out of weight range / volume weight
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'no',
			recipient_zip_code:      '3400',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 501, volume_weight: 501)])
		)

		result   = price_calculations
		expected = false

		assert expected == result, "result: #{result}, expected: #{expected}"

		# No matching zone
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'ded',
			recipient_zip_code:      '34000',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 20, volume_weight: 1)])
		)

		result   = price_calculations
		expected = false

		assert expected == result, "result: #{result}, expected: #{expected}"

	end


end

require 'test_helper'

class TNTExpressImportPriceDocumentTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/tnt_express_import_final.xlsx'

	test "TNT Express Import" do

		# Parsing
		price_document = parser.parse(price_document_class: TNTPriceDocument, filename: FILENAME)
		no_parsing_errors = select_fatal_errors(parsing_errors: price_document.parsing_errors).empty?

		assert no_parsing_errors

		#
		# Price Calculation
		#

		# Price single zone 1
		price_calculations = price_document.calculate_price_for_shipment(
			import: true,
			sender_country_code:  'de',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 163.77 + 163.77 * 0.2 + [3.75, [75, 5*0.37].min].max + 85

		assert_in_error_margin_delta(expected, result)

		# Price single zone 7
		price_calculations = price_document.calculate_price_for_shipment(
			import: true,
			sender_country_code:  'ge',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 481.91 + 481.91 * 0.2 + [3.75, [75, 5*0.37].min].max + 85 + 58.9

		assert_in_error_margin_delta(expected, result)

		# No matching zone
		price_calculations = price_document.calculate_price_for_shipment(
			import: true,
			sender_country_code:  'ded',
			sender_zip_code:      '34000',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 20, volume_weight: 1)])
		)

		result   = price_calculations
		expected = false

		assert expected == result, "result: #{result}, expected: #{expected}"

		# No matching zone
		price_calculations = price_document.calculate_price_for_shipment(
			import: true,
			sender_country_code:  'ded',
			sender_zip_code:      '34000',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 20, volume_weight: 1)])
		)

		result   = price_calculations
		expected = false

		assert expected == result, "result: #{result}, expected: #{expected}"

		# Use sender country
		price_calculations = price_document.calculate_price_for_shipment(
			import: true,
			sender_country_code:'ge',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 481.91 + 481.91 * 0.2 + [3.75, [75, 5*0.37].min].max + 85 + 58.9

		assert_in_error_margin_delta(expected, result)

	end


end

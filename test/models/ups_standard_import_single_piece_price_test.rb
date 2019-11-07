require 'test_helper'

class UPSStandardImportSinglePiecePriceTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/ups_standard_import_single_piece_final.xlsx'

	test "UPS Standard Import Single Piece" do

		# Parsing
		price_document = parser.parse(price_document_class: UPSPriceDocument, filename: FILENAME)
		no_parsing_errors = select_fatal_errors(parsing_errors: price_document.parsing_errors).empty?

		assert no_parsing_errors

		#
		# Price Calculation
		#

		# Price single zone from zip codes
		price_calculations = price_document.calculate_price_for_shipment(
			import: true,
			sender_country_code:  'se',
			sender_zip_code: '24400',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 10, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 95.58 + (95.58 * 0.1)

		assert_in_error_margin_delta(expected, result)

		# Price single no zipcodes, default zone
		price_calculations = price_document.calculate_price_for_shipment(
			import: true,
			sender_country_code:  'se',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 10, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 137.7 + (137.7 * 0.1)

		assert_in_error_margin_delta(expected, result)

		# Price large package charge
		price_calculations = price_document.calculate_price_for_shipment(
			import: true,
			sender_country_code:  'se',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 100, height: 100, weight: 10, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 137.7 + (137.7 * 0.1) + 90

		assert_in_error_margin_delta(expected, result)

		# Price two large package charges
		price_calculations = price_document.calculate_price_for_shipment(
			import: true,
			sender_country_code:  'se',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 100, height: 100, weight: 10, volume_weight: 5),
																														PackageDimension.new(length: 5, width: 100, height: 100, weight: 5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 149.76 + (149.76 * 0.1) + 90 * 2

		assert_in_error_margin_delta(expected, result)

	end


end
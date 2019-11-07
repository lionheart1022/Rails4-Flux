require 'test_helper'

class UPSStandardPriceTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/ups_standard_final.xlsx'

	test "UPS Standard" do

		# Parsing
		price_document = parser.parse(price_document_class: UPSPriceDocument, filename: FILENAME)
		no_parsing_errors = select_fatal_errors(parsing_errors: price_document.parsing_errors).empty?

		assert no_parsing_errors

		#
		# Price Calculation
		#

		# Weight range
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'mc',
			recipient_zip_code: '24400',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 22, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 211.14 + (211.14 * 0.1)

		assert_in_error_margin_delta(expected, result)

		# weight range round up
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'mc',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 40.1, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 264.06 + (264.06 * 0.1)

		assert_in_error_margin_delta(expected, result)

		# Price large package charge
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'mc',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 100, height: 100, weight: 10, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 167.4 + (167.4 * 0.1) + 90

		assert_in_error_margin_delta(expected, result)

		# Price two large package
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'mc',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 100, height: 100, weight: 80, volume_weight: 5),
																														PackageDimension.new(length: 5, width: 100, height: 100, weight: 5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 319.32 + (319.32 * 0.1) + (90 * 2)

		assert_in_error_margin_delta(expected, result)

	end


end
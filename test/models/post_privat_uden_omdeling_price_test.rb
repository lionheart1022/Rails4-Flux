require 'test_helper'

class PostPrivatUdenOmdelingPriceTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/post_privat_uden_omdeling_final.xlsx'

	test "PostDK Privat uden omdeling" do

		# Parsing
		price_document = parser.parse(price_document_class: PostDKPriceDocument, filename: FILENAME)
		no_parsing_errors = select_fatal_errors(parsing_errors: price_document.parsing_errors).empty?

		assert no_parsing_errors

		#
		# Price Calculation
		#

		# Price single 
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			recipient_zip_code:      '4001',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 32.08 + (32.08 * 0.08)

		assert_in_error_margin_delta(expected, result)

		# Price single package based calculation
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			recipient_zip_code:      '4001',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 4, volume_weight: 1),
																														PackageDimension.new(length: 5, width: 5, height: 5, weight: 1, volume_weight: 1)])
		)

		result   = price_calculations.total
		expected = 32.08 + (32.08 * 0.08) + 28.82 + (28.82 * 0.08)

		assert_in_error_margin_delta(expected, result)

		# Price single round up
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 15.2)])
		)

		result   = price_calculations.total
		expected = 48.89 + (48.89 * 0.08)

		assert_in_error_margin_delta(expected, result)

		# Weight range
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 25, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 323.89 + (4 * 275) + ((323.89 + 4 * 275) * 0.08)

		assert_in_error_margin_delta(expected, result)

		# Weight range round up
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 20.1, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 323.89 + 323.89 * 0.08

		assert_in_error_margin_delta(expected, result)

		# Out of weight range
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 200.1, volume_weight: 5)])
		)

		result   = price_calculations
		expected = false

		assert result == expected



	end

		
end

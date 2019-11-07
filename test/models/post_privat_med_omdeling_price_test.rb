require 'test_helper'

class PostPrivatMedOmdelingPriceTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/post_privat_med_omdeling_final.xlsx'

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
			margin: 10,
			recipient_country_code:  'dk',
			recipient_zip_code:      '4001',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 48.38 * 1.1 + (48.38 * 1.1 * 0.09)

		assert_in_error_margin_delta(expected, result)

		# Price single package based calculation
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			recipient_zip_code:      '4001',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 4, volume_weight: 1),
																														PackageDimension.new(length: 5, width: 5, height: 5, weight: 1, volume_weight: 1)])
		)

		result   = price_calculations.total
		expected = 48.38 + (48.38 * 0.09) + 45.12 + (45.12 * 0.09)

		assert_in_error_margin_delta(expected, result)

		# Weight range
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 24, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 115.19 + (3 * 50) + ((115.19 + 3 * 50) * 0.09)

		assert_in_error_margin_delta(expected, result)

	end


end

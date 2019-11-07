require 'test_helper'

class PostErhvervPriceTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/post_erhverv_final.xlsx'

	test "PostDK Erhverv" do

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
		expected = 23 + 23*0.09

		assert_in_error_margin_delta(expected, result)

		# Price single
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'dk',
			recipient_zip_code:      '4001',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 10.5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 23 + 23*0.09

		assert_in_error_margin_delta(expected, result)

		# Price single
		price_calculations = price_document.calculate_price_for_shipment(
			margin: 20.0,
			recipient_country_code:  'dk',
			recipient_zip_code:      '4001',
			package_dimensions: PackageDimensions.new(dimensions:[
				PackageDimension.new(length: 5, width: 5, height: 5, weight: 10.5, volume_weight: 5),
				PackageDimension.new(length: 5, width: 5, height: 5, weight: 10.5, volume_weight: 5),
				PackageDimension.new(length: 5, width: 5, height: 5, weight: 10.5, volume_weight: 5)
				])
		)

		result   = price_calculations.total
		expected = (3 * 23 * 1.2) + (3 * 23 * 1.2 * 0.09)

		assert_in_error_margin_delta(expected, result)


	end


end

require 'test_helper'

class TNTEconomyExpressPriceTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/tnt_economy_express_final.xlsx'

	test "TNT Economy Express" do

		# Parsing
		price_document = parser.parse(price_document_class: TNTPriceDocument, filename: FILENAME)
		no_parsing_errors = select_fatal_errors(parsing_errors: price_document.parsing_errors).empty?

		assert no_parsing_errors

		#
		# Price Calculation
		#

		# Weight range first Prices worksheet
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'de',
			recipient_zip_code:      '34001',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 126.52 + (126.52 * 0.2) + [3.75, [75, 5 * 0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# Price single second Prices worksheet
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'gu',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 580.93 + (580.93 * 0.2) + [3.75, [75, 5 * 0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# Weight range round up
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'de',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 10.1, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 144.59 + (144.59 * 0.2) + [3.75, [75, 11 * 0.37].min].max

		assert_in_error_margin_delta(expected, result)



	end


end

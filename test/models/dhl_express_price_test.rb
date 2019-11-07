require 'test_helper'

class DHLExpressPriceTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/dhl_express_final.xlsx'

	test "DHL Express" do

		# Parsing
		price_document = parser.parse(price_document_class: DHLPriceDocument, filename: FILENAME)
		no_parsing_errors = select_fatal_errors(parsing_errors: price_document.parsing_errors).empty?

		assert no_parsing_errors

		#
		# Price Calculation
		#

		# Price single 
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'cz',
			recipient_zip_code:      '4001',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 15, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 483 + (483 * 0.2) + 2*100

		assert_in_error_margin_delta(expected, result)

		# Weight range lower bound
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'cz',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 51, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = 872 + 872*0.2 + (2 * 100)


		assert_in_error_margin_delta(expected, result)

		# Weight range upper bound
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'cz',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 500, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = (872 + (500-51) * 34) + (872 + (500-51) * 34)*0.2 + (2 * 100)


		assert_in_error_margin_delta(expected, result)

		# Weight range round up to upper bound
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'cz',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 499.6, volume_weight: 5)])
		)

		result   = price_calculations.total
		expected = (872 + (500-51) * 34) + (872 + (500-51) * 34)*0.2 + (2 * 100)


		assert_in_error_margin_delta(expected, result)

	end

		
end

require 'test_helper'

class TNTExpressDocumentPriceDocumentTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/tnt_express_document_final.xlsx'

	test "TNT Expresss Document" do

		# Parsing
		price_document = parser.parse(price_document_class: TNTPriceDocument, filename: FILENAME)
		no_parsing_errors = select_fatal_errors(parsing_errors: price_document.parsing_errors).empty?

		assert no_parsing_errors

		#
		# Price Calculation
		#

		# Price single round up
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'nl',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 0.1, volume_weight: 0.1)])
		)

		result   = price_calculations.total
		expected = 76.49 + (76.49 * 0.2) + [3.75, [75, 0.25*0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# weight range
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'nl',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 5, volume_weight: 0.1)])
		)

		result   = price_calculations.total
		expected = 163.77 + (163.77 * 0.2) + [3.75, [75, 0.25*0.37].min].max

		assert_in_error_margin_delta(expected, result)

		# zero weight
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'nl',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 0, volume_weight: 0)])
		)

		result   = price_calculations.total
		expected = 76.49 + (76.49 * 0.2) + [3.75, [75, 0.25*0.37].min].max

		assert_in_error_margin_delta(expected, result)

	end


end

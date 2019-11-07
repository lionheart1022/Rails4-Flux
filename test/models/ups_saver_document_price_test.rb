require 'test_helper'

class UPSSaverDocumentPriceTest < ActiveSupport::TestCase

	 # Filenames
  FILENAME = 'test/price_documents/ups_saver_document_final.xlsx'

	test "UPS Saver Document" do

		# Parsing
		price_document = parser.parse(price_document_class: UPSPriceDocument, filename: FILENAME)
		no_parsing_errors = select_fatal_errors(parsing_errors: price_document.parsing_errors).empty?

		assert no_parsing_errors

		#
		# Price Calculation
		#

		# Price single with zip
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'es',
			recipient_zip_code: '51002',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 0.5, volume_weight: 0)])
		)

		result   = price_calculations.total
		expected = 196.02 + (196.02 * 0.18)

		assert_in_error_margin_delta(expected, result)

		# Price single no zip
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'es',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 0.5, volume_weight: 0)])
		)

		result   = price_calculations.total
		expected = 106.47 + (106.47 * 0.18)

		assert_in_error_margin_delta(expected, result)

		# Price single no matching zip
		price_calculations = price_document.calculate_price_for_shipment(
			recipient_country_code:  'es',
			recipient_zip_code: '1111111111',
			package_dimensions: PackageDimensions.new(dimensions:[PackageDimension.new(length: 5, width: 5, height: 5, weight: 0.5, volume_weight: 0)])
		)

		result   = price_calculations.total
		expected = 106.47 + (106.47 * 0.18)

		assert_in_error_margin_delta(expected, result)


	end


end
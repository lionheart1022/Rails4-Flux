require 'test_helper'

class FedExShipperLib::ShippingResponseTest < Minitest::Test
  describe 'ShippingResponse' do
    it 'parses a successful response' do
      success_response = File.read('test/fixtures/models/fed_ex/open_shipment_response.xml')
      response = FedExShipperLib::ShippingResponse.new(success_response, 1)
      assert response.success?
      assert response.awb == '794644773540'
      assert_empty response.warnings_and_notes
      assert_empty response.errors
    end

    it 'parses a response with warnings' do
      success_response = File.read('test/fixtures/models/fed_ex/open_shipment_response_with_warnings.xml')
      response = FedExShipperLib::ShippingResponse.new(success_response, 1)
      assert response.success?
      assert response.awb == '794644782497'
      assert_empty response.errors

      first_warning = response.warnings_and_notes.fetch(0)
      assert first_warning.severity == 'WARNING'
      assert first_warning.code == '2469'
      assert first_warning.description == 'shipTimestamp is invalid'

      second_warning = response.warnings_and_notes.fetch(1)
      assert second_warning.severity == 'WARNING'
      assert second_warning.code == '7000'
      assert second_warning.description == 'Unable to obtain courtesy rates.'
    end

    it 'parses a response with errors' do
      success_response = File.read('test/fixtures/models/fed_ex/open_shipment_response_with_errors.xml')
      response = FedExShipperLib::ShippingResponse.new(success_response, 1)

      assert !response.success?
      assert_nil response.awb

      first_error = response.errors.fetch(0)
      assert first_error.severity == 'ERROR'
      assert first_error.code == '6647'
      assert first_error.description == 'ShippingChargesPayment - Payor country code must match either Origin or Destination country code'
    end
  end
end

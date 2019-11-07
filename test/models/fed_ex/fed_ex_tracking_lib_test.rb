require 'test_helper'

class FedExTrackingLibTest < Minitest::Test
  describe 'FedExTrackingLib' do
    before do
      @credentials = FedExCredentials.new(
        'e3JYB2UmrCRail5A',
        'Nyl5WroxCLn1VCUPqwn0wmPiB',
        '510087305',
        '118762816'
      )
      @carrier_product = FedExInternationalEconomyCarrierProduct.new
    end

    def stubbed_client(response_body)
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('/web-services') { |env| [200, {}, response_body] }
      end
      Faraday.new do |builder|
        builder.adapter :test, stubs
      end
    end

    it 'extracts trackings from response' do
      success_response = File.read('test/fixtures/models/fed_ex/tracking_response.xml')
      tracking_lib = FedExTrackingLib.new(
        faraday_connection: stubbed_client(success_response)
      )
      trackings = tracking_lib.track(credentials: @credentials, awb: '12341234')
      assert trackings.size == 4
    end

    it 'handles a failed tracking request' do
      response = File.read('test/fixtures/models/fed_ex/failed_tracking_response.xml')
      tracking_lib = FedExTrackingLib.new(
        faraday_connection: stubbed_client(response)
      )

      exception = assert_raises(TrackingLib::Errors::TrackingFailedException) do
        tracking_lib.track(credentials: @credentials, awb: '12341234')
      end

      assert exception.code == '9040'
      assert exception.description == 'This tracking number cannot be found. Please check the number or contact the sender.'
    end
  end
end

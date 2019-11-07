require 'test_helper'

class FedExShipperLibTest < Minitest::Test
  describe 'FedExShipperLib' do
    before do
      @credentials = FedExCredentials.new(
        'e3JYB2UmrCRail5A',
        'Nyl5WroxCLn1VCUPqwn0wmPiB',
        '510087305',
        '118762816'
      )
      @carrier_product = FedExInternationalEconomyCarrierProduct.new
      @recipient = FactoryBot.build(:recipient)
      @sender = FactoryBot.build(:sender_from_usa)
      @shipment = FactoryBot.build(:dutiable_shipment)
    end

    def stubbed_client(response_body)
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('/web-services') { |env| [200, {}, response_body] }
      end
      Faraday.new do |builder|
        builder.adapter :test, stubs
      end
    end

    it 'books a shipment' do
      success_response = File.read('test/fixtures/models/fed_ex/open_shipment_response.xml')
      shipper_lib = FedExShipperLib.new(
        faraday_connection: stubbed_client(success_response)
      )
      booking = shipper_lib.book_shipment(
        credentials: @credentials,
        shipment: @shipment,
        sender: @sender,
        recipient: @recipient,
        carrier_product: @carrier_product
      )
      assert booking.awb == '794644773540'
    end

    it 'fails booking a sipment' do
      failing_response = File.read('test/fixtures/models/fed_ex/open_shipment_response_with_errors.xml')
      shipper_lib = FedExShipperLib.new(
        faraday_connection: stubbed_client(failing_response)
      )
      assert_raises(BookingLib::Errors::BookingFailedException) do
        shipper_lib.book_shipment(
          credentials: @credentials,
          shipment: @shipment,
          sender: @sender,
          recipient: @recipient,
          carrier_product: @carrier_product
        )
      end
    end
  end
end

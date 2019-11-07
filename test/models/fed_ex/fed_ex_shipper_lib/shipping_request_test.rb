require 'test_helper'

class FedExShipperLib::ShippingRequestTest < Minitest::Test
  describe 'ShippingRequest' do
    def strip_xml(xml)
      xml.split("\n").map(&:strip).map(&:chomp).join('')
      # xml
    end

    it 'builds a proper xml request' do
      credentials = FedExCredentials.new(
        'e3JYB2UmrCRail5A',
        'Nyl5WroxCLn1VCUPqwn0wmPiB',
        '510087305',
        '118762816'
      )
      carrier_product = FedExInternationalEconomyCarrierProduct.new
      recipient = FactoryBot.build(:recipient)
      sender = FactoryBot.build(:sender)
      shipment = FactoryBot.build(:dutiable_shipment,
                                  shipping_date: Date.new(2016, 11, 25),
                                  unique_shipment_id: '627-213-391')
      request = FedExShipperLib::ShippingRequest.new(
        credentials: credentials,
        shipment: shipment,
        sender: sender,
        recipient: recipient,
        carrier_product: carrier_product
      )
      expected = strip_xml(File.read('test/fixtures/models/fed_ex/create_open_shipment.xml'))
      assert_equal(strip_xml(request.as_string), expected)
    end

    describe "shipment within EU" do
      it "has dummy customs details when without info" do
        shipment = FactoryBot.build(:shipment)
        recipient = FactoryBot.build(:recipient, country_code: "DK")
        sender = FactoryBot.build(:sender, country_code: "SE")
        request = FedExShipperLib::ShippingRequest.new(
          credentials: nil,
          shipment: shipment,
          sender: sender,
          recipient: recipient,
          carrier_product: nil
        )

        customs = request.customs

        assert_equal("EUR", customs.currency)
        assert_equal("0.00", customs.amount)
        assert_nil(customs.code)
      end

      it "has given customs details when info is given" do
        shipment = FactoryBot.build(:dutiable_shipment)
        recipient = FactoryBot.build(:recipient, country_code: "DK")
        sender = FactoryBot.build(:sender, country_code: "SE")
        request = FedExShipperLib::ShippingRequest.new(
          credentials: nil,
          shipment: shipment,
          sender: sender,
          recipient: recipient,
          carrier_product: nil
        )

        customs = request.customs

        assert_equal("DKK", customs.currency)
        assert_equal("1500.00", customs.amount)
        assert_equal("010190", customs.code)
      end
    end

    describe "shipment outside EU" do
      it "has dutiable info" do
        shipment = FactoryBot.build(:dutiable_shipment)
        recipient = FactoryBot.build(:recipient)
        sender = FactoryBot.build(:sender_from_usa)
        request = FedExShipperLib::ShippingRequest.new(
          credentials: nil,
          shipment: shipment,
          sender: sender,
          recipient: recipient,
          carrier_product: nil
        )

        assert request.dutiable?
      end

      it "has no dutiable info" do
        shipment = FactoryBot.build(:shipment)
        recipient = FactoryBot.build(:recipient)
        sender = FactoryBot.build(:sender_from_usa)
        request = FedExShipperLib::ShippingRequest.new(
          credentials: nil,
          shipment: shipment,
          sender: sender,
          recipient: recipient,
          carrier_product: nil
        )

        assert !request.dutiable?
      end
    end
  end
end

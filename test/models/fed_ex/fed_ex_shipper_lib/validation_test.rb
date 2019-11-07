require 'test_helper'

class FedExShipperLib::ValidationTest < Minitest::Test
  describe 'Validation' do
    it "validates without errors" do
      sender = FactoryBot.build(:sender)
      recipient = FactoryBot.build(:recipient)
      shipment = FactoryBot.build(:shipment)
      validation = FedExShipperLib::Validation.new(
        shipment: shipment,
        sender: sender,
        recipient: recipient
      )
      validation.validate

      assert validation.valid?
      assert validation.errors.size == 0
    end

    it "validations with all errors" do
      bad_contact_attributes = {
        company_name: "The Name of This Company Is Too Insane Long",
        attention: "The Name of This Person Is Also Too Damn Long",
        address_line1: "This Street Does Not Event Exist But The Name Is Long",
        address_line2: "This Line Does Not Event Exist But The Name Is Long",
        city: "Ufutufubufulugidugilalalalalala"
      }

      sender = FactoryBot.build(:sender, bad_contact_attributes)
      recipient = FactoryBot.build(:recipient, bad_contact_attributes)
      shipment = FactoryBot.build(:shipment,
        reference: "I am Just writing this long reference to make it fail",
        description: "FedEx allows a really really really really long desc, but this one is too long",
        shipping_date: 10.days.ago.to_date
      )

      validation = FedExShipperLib::Validation.new(
        shipment: shipment,
        sender: sender,
        recipient: recipient
      )
      validation.validate

      error_codes = validation.errors.map(&:code)

      assert error_codes == [
        "CF-FedEx-shipment-in-the-past",
        "CF-FedEx-shipment_reference-length",
        "CF-FedEx-shipment_description-length",
        "CF-FedEx-sender_company_name-length",
        "CF-FedEx-sender_attention-length",
        "CF-FedEx-sender_address_line1-length",
        "CF-FedEx-sender_address_line2-length",
        "CF-FedEx-sender_city-length",
        "CF-FedEx-recipient_company_name-length",
        "CF-FedEx-recipient_attention-length",
        "CF-FedEx-recipient_address_line1-length",
        "CF-FedEx-recipient_address_line2-length",
        "CF-FedEx-recipient_city-length"
      ]
    end
  end
end

require "test_helper"

class ShipmentVatPolicyTest < ActiveSupport::TestCase
  test "includes vat with shipment from Denmark to Sweden" do
    sender = FactoryBot.build(:sender)
    recipient = FactoryBot.build(:recipient_from_sweden)
    shipment = FactoryBot.build(:shipment, recipient: recipient, sender: sender)

    assert ShipmentVatPolicy.new(shipment).include_vat?
  end

  test "includes vat with shipment from Sweden to Denmark" do
    sender = FactoryBot.build(:sender_from_sweden)
    recipient = FactoryBot.build(:recipient)
    shipment = FactoryBot.build(:shipment, recipient: recipient, sender: sender)

    assert ShipmentVatPolicy.new(shipment).include_vat?
  end

  test "does not include vat with shipment from USA to Denmark" do
    sender = FactoryBot.build(:sender_from_usa)
    recipient = FactoryBot.build(:recipient)
    shipment = FactoryBot.build(:shipment, recipient: recipient, sender: sender)

    refute ShipmentVatPolicy.new(shipment).include_vat?
  end

  test "does not include vat with shipment from Denmark to USA" do
    sender = FactoryBot.build(:sender_from_usa)
    recipient = FactoryBot.build(:recipient)
    shipment = FactoryBot.build(:shipment, recipient: recipient, sender: sender)

    refute ShipmentVatPolicy.new(shipment).include_vat?
  end
end

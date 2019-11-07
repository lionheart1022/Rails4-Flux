class ShipmentVatPolicy
  attr_reader :shipment

  def initialize(shipment)
    @shipment = shipment
  end

  def include_vat?
    shipment.sender.in_eu? && shipment.recipient.in_eu?
  end
end

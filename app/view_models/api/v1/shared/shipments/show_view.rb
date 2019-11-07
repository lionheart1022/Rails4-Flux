class API::V1::Shared::Shipments::ShowView
  attr_reader :main_view, :shipment, :carrier_product, :carrier, :sender, :recipient, :advanced_price, :show_detailed_price

  def initialize(shipment: nil, carrier_product: nil, carrier: nil, sender: nil, recipient: nil, advanced_price: nil, show_detailed_price: nil)
    @shipment        = shipment
    @carrier_product = carrier_product
    @carrier         = carrier
    @sender          = sender
    @recipient       = recipient
    @advanced_price  = advanced_price
    @show_detailed_price = show_detailed_price

    state_general
  end


  def not_found_text
    "shipment not found"
  end

  private

  def state_general
    @main_view = "api/v1/shared/shipments/show"
  end
end

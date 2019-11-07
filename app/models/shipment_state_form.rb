class ShipmentStateForm
  include ActiveModel::Model

  class << self
    def build_for_shipment(shipment)
      new(state: shipment.state)
    end
  end

  attr_accessor :state
  attr_accessor :awb
  attr_accessor :comment

  def available_state_options
    all_options = ViewHelper::Shipments.states_for_select
    all_options.reject! { |(_, option_for_state)| option_for_state == Shipment::States::CREATED } unless state == Shipment::States::CREATED
    all_options
  end
end

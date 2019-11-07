class PickupStateForm
  include ActiveModel::Model

  class << self
    def build_for_pickup(pickup)
      new(state: pickup.state)
    end
  end

  attr_accessor :state
  attr_accessor :comment

  def available_state_options
    all_options = ViewHelper::Pickups.states_for_select
    all_options.reject! { |(_, option_for_state)| option_for_state == Pickup::States::CREATED } unless state == Pickup::States::CREATED
    all_options
  end
end

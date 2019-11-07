class Companies::ProcessPickupStateChange
  STATE_EVENT_MAPPING = {
    Pickup::States::BOOKED => Pickup::Events::BOOK,
    Pickup::States::PICKED_UP => Pickup::Events::PICKUP,
    Pickup::States::PROBLEM => Pickup::Events::REPORT_PROBLEM,
    Pickup::States::CANCELLED => Pickup::Events::CANCEL,
  }

  attr_reader :company
  attr_reader :pickup

  attr_accessor :state
  attr_accessor :comment

  def initialize(company:, pickup:, state_change_params: {})
    @company = company
    @pickup = pickup

    state_change_params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def perform!
    case state
    when Pickup::States::BOOKED
      pickup.book(comment: comment)
    when Pickup::States::PICKED_UP
      pickup.pickup(comment: comment)
    when Pickup::States::PROBLEM
      pickup.report_problem(comment: comment)
    when Pickup::States::CANCELLED
      pickup.cancel(comment: comment)
    end

    if event_from_state = STATE_EVENT_MAPPING[state]
      PickupNotificationManager.handle_event(pickup, event: event_from_state)
    end

    true
  end
end

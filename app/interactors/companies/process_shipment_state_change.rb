class Companies::ProcessShipmentStateChange
  SHIPMENT_STATE_EVENT_MAPPING = {
    Shipment::States::BOOKED => Shipment::Events::BOOK,
    Shipment::States::IN_TRANSIT => Shipment::Events::SHIP,
    Shipment::States::DELIVERED_AT_DESTINATION => Shipment::Events::DELIVERED_AT_DESTINATION,
    Shipment::States::PROBLEM => Shipment::Events::REPORT_PROBLEM,
    Shipment::States::CANCELLED => Shipment::Events::CANCEL,
  }

  attr_reader :company
  attr_reader :shipment

  attr_accessor :state
  attr_accessor :awb
  attr_accessor :comment

  def initialize(company:, shipment:, state_change_params: {})
    @company = company
    @shipment = shipment

    state_change_params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def awb=(value)
    @awb = value.presence
  end

  def perform!
    case state
    when Shipment::States::BOOKED
      shipment.book(awb: awb, comment: comment)
    when Shipment::States::IN_TRANSIT
      shipment.ship(comment: comment)
    when Shipment::States::DELIVERED_AT_DESTINATION
      shipment.delivered_at_destination(comment: comment)
    when Shipment::States::PROBLEM
      shipment.report_problem(comment: comment)
    when Shipment::States::CANCELLED
      shipment.cancel(comment: comment)
    end

    if event_from_state = SHIPMENT_STATE_EVENT_MAPPING[state]
      EventManager.handle_event(event: event_from_state, event_arguments: { shipment_id: shipment.id })
    end

    true
  end
end

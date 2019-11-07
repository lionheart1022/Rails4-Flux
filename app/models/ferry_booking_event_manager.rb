class FerryBookingEventManager
  class << self
    def handle_event(event: nil, event_arguments: nil)
      ShipmentStatsManager.handle_event(event: event, event_arguments: event_arguments)
      FerryBookingNotificationManager.handle_event(event: event, event_arguments: event_arguments)
    end
  end
end

class EventManager
  class << self
    def handle_event(event: nil, event_arguments: nil)
      ShipmentExportManager.handle_event(event: event, event_arguments: event_arguments)
      ShipmentStatsManager.handle_event(event: event, event_arguments: event_arguments)
      ShipmentNotificationManager.handle_event(event: event, event_arguments: event_arguments)
      CallbackManager.handle_event(event: event, event_arguments: event_arguments)
    end
  end
end

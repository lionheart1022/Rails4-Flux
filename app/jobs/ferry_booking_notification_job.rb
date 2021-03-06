class FerryBookingNotificationJob < ActiveJob::Base
  queue_as :booking

  def perform(shipment_id, event = nil)
    shipment = Shipment.find(shipment_id)
    FerryBookingNotificationManager.handle_event_now(shipment, event: event)
  end
end

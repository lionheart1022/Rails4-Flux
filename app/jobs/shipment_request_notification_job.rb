class ShipmentRequestNotificationJob < ActiveJob::Base
  queue_as :booking

  def perform(shipment_request_id, event = nil)
    shipment_request = ShipmentRequest.find(shipment_request_id)
    ShipmentRequestNotificationManager.handle_event_now(shipment_request, event: event)
  end
end

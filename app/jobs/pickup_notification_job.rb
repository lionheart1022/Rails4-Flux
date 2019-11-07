class PickupNotificationJob < ActiveJob::Base
  queue_as :booking

  def perform(pickup_id, event = nil)
    pickup = Pickup.find(pickup_id)
    PickupNotificationManager.handle_event_now(pickup, event: event)
  end
end

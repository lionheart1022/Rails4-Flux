class CarrierPickupRequestJob < ActiveJob::Base
  queue_as :booking

  def perform(carrier_pickup_request_id)
    carrier_pickup_request = CarrierPickupRequest.find(carrier_pickup_request_id)
    carrier_pickup_request.with_lock do
      carrier_pickup_request.handle!
    end
  end
end

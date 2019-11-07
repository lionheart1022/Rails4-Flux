class FerryBookingRequestJob < ActiveJob::Base
  queue_as :booking

  def perform(ferry_booking_id)
    ferry_booking = FerryBooking.find(ferry_booking_id)
    ferry_booking.requests_to_handle.each do |request|
      request.handle_with_lock!
    end
  end
end

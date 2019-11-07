class FerryBookingDownloadJob < ActiveJob::Base
  MAX_REENQUEUE_ATTEMPTS = 4

  queue_as :booking

  def perform(ferry_booking_id, attempt: 1)
    ferry_booking = FerryBooking.find(ferry_booking_id)

    return unless ferry_booking.waiting_for_response?

    ferry_booking.sftp_download_response! # This will potentially also download responses for other ferry bookings but that's fine

    FerryBookingDownload.handle! # This will potentially also handle responses for other ferry bookings but that's fine

    ferry_booking.reload

    if ferry_booking.waiting_for_response? && attempt < MAX_REENQUEUE_ATTEMPTS
      # Re-enqueue job if still waiting for response
      self.class.set(wait: 5.minutes).perform_later(ferry_booking.id, attempt: attempt + 1)

      # If after 4 attempts, ~ 20 minutes, we still haven't received a response a scheduled job will
      # be responsible for handling the ferry booking.
    end
  end
end

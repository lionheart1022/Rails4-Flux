class FerryBookingEvent < EventV2
  AVAILABLE_LABELS = %w(
    booking_created
    booking_updated
    booking_cancelled

    booking_delivered
    booking_delivery_failed
    booking_confirmed
    booking_failed

    booking_cancellation_delivered
    booking_cancellation_delivery_failed
    booking_cancellation_confirmed
    booking_cancellation_failed
  )

  has_one :snapshot, class_name: "FerryBookingSnapshot", foreign_key: "event_id"

  validates :label, inclusion: { in: AVAILABLE_LABELS }

  class << self
    def new_booking_created_event(attrs = {})
      current_state_hash = attrs.delete(:current_state_hash)

      new(attrs) do |event|
        event.label = "booking_created"
        event.build_snapshot(
          initial_state: true,
          current_state: current_state_hash,
          diff: nil,
        )
      end
    end

    def new_booking_updated_event(attrs = {})
      previous_state_hash = attrs.delete(:previous_state_hash)
      current_state_hash = attrs.delete(:current_state_hash)

      new(attrs) do |event|
        event.label = "booking_updated"
        event.build_snapshot(
          initial_state: false,
          current_state: current_state_hash,
          diff: event.produce_diff(previous_state_hash, current_state_hash),
        )
      end
    end

    def new_booking_cancelled_event(attrs = {})
      new(attrs) do |event|
        event.label = "booking_cancelled"
      end
    end
  end

  def human_friendly_label
    label.humanize if label
  end

  def produce_diff(previous_state_hash, current_state_hash)
    diff = []

    current_state_hash.each do |field, current_value|
      previous_value = previous_state_hash[field]

      if previous_value != current_value
        diff << { "field" => field, "before" => previous_value, "after" => current_value }
      end
    end

    diff
  end
end

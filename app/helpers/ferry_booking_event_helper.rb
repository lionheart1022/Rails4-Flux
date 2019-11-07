module FerryBookingEventHelper
  def ferry_booking_event_details(event)
    if snapshot = event.snapshot
      return (
        if snapshot.initial_state?
          render_ferry_booking_initial_state(snapshot.current_state)
        elsif snapshot.diff?
          render_ferry_booking_diff(snapshot.diff)
        else
          content_tag(:p) do
            content_tag(:em, "No changes")
          end
        end
      )
    end

    simple_format event.description
  end

  private

  def render_ferry_booking_initial_state(state)
    content_tag(:ul, class: "snapshot_state") do
      state.each do |label, value|
        formatter = FerryBookingFieldFormatter.new(label: label, value: value)

        concat (
          content_tag(:li) do
            concat content_tag(:span, formatter.formatted_label, class: "snapshot_state_label")
            concat content_tag(:span, formatter.formatted_value.presence || content_tag(:em, "Empty"), class: "snapshot_state_value")
          end
        )
      end
    end
  end

  def render_ferry_booking_diff(diffs)
    content_tag(:ul, class: "snapshot_state") do
      diffs.each do |diff|
        formatter = FerryBookingFieldFormatter.new(label: diff["field"])

        concat (
          content_tag(:li) do
            concat content_tag(:span, formatter.formatted_label, class: "snapshot_state_label")
            concat (
              content_tag(:span, class: "snapshot_state_value") do
                concat (
                  content_tag(:span) do
                    formatter.formatted_value(diff["before"]).presence || content_tag(:em, "Empty")
                  end
                )

                concat content_tag(:span, "→", class: "spanshot_stat_transition_arrow")

                concat (
                  content_tag(:span) do
                    formatter.formatted_value(diff["after"]).presence || content_tag(:em, "Empty")
                  end
                )
              end
            )
          end
        )
      end
    end
  end

  class FerryBookingFieldFormatter
    attr_accessor :label
    attr_accessor :value

    def initialize(label:, value: nil)
      self.label = label
      self.value = value
    end

    def formatted_label
      case label
      when "route_id"
        "Route"
      else
        label.humanize
      end
    end

    def formatted_value(override_value = nil)
      value = override_value || self.value

      case label
      when "route_id"
        FerryRoute.where(id: value).pluck(:name).first
      when "truck_type"
        FerryBooking.human_friendly_truck_type(value)
      when "with_driver"
        value ? "Yes" : "No"
      when "truck_length"
        "#{value} m"
      when "cargo_weight"
        "#{value} kg"
      when "empty_cargo"
        value ? "Yes" : "No"
      else
        value
      end
    end
  end
end

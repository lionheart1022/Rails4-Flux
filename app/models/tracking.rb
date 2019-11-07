class Tracking < ActiveRecord::Base
  has_one :event, as: :linked_object

  class << self
    def build_tracking(params)
      permitted_attrs = [
        :type,
        :status,
        :description,
        :signatory,
        :expected_delivery_date,
        :expected_delivery_time,
        :event_date,
        :event_time,
        :event_country,
        :event_city,
        :event_zip_code,
        :depot_name,
      ]

      new(params.slice(*permitted_attrs))
    end

    def find_shipment_trackings(shipment_id: nil)
      self
        .joins("LEFT JOIN events ON events.linked_object_id = trackings.id AND events.linked_object_type = trackings.type")
        .where(events: { reference_id: shipment_id, reference_type: "Shipment" })
    end

    def already_reported?(shipment_id: nil, event_time: nil)
      self
        .find_shipment_trackings(shipment_id: shipment_id)
        .where(event_time: event_time)
        .exists?
    end

    def latest_tracking(shipment_id: nil)
      self
        .find_shipment_trackings(shipment_id: shipment_id)
        .order(:created_at)
        .last
    end

    def should_change_state?(shipment_id: nil, status: nil)
      if tracking = latest_tracking(shipment_id: shipment_id)
        tracking.status != status
      else
        true
      end
    end
  end
end

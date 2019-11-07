class Event < ActiveRecord::Base
  belongs_to :company
  belongs_to :customer
  belongs_to :reference, polymorphic: true
  belongs_to :linked_object, polymorphic: true

  serialize :event_changes, Hash

  # PUBLIC API

  class << self

    def create_event(company_id: nil, customer_id: nil, event_data: nil)
      event = self.new({
        company_id:         company_id,
        customer_id:        customer_id,
        reference_type:     event_data[:reference_type],
        reference_id:       event_data[:reference_id],
        event_type:         event_data[:event_type],
        event_changes:      event_data[:event_changes],
        description:        event_data[:description],
        linked_object_type: event_data[:linked_object_type],
        linked_object_id:   event_data[:linked_object_id],
      })

      event.save!

      return event
    end
  end

  def references_request?
    self.linked_object.present? && self.linked_object.is_a?(CarrierProductAutobookRequest)
  end

  def references_tracking?
    self.linked_object.present? && self.linked_object.is_a?(Tracking)
  end

  # helper methods for extracting data from event changes
  def old_values_from_event_changes
    event_changes_hash = self.event_changes.to_hash
    old_values_hash = event_changes_hash.merge(event_changes_hash) {|key, value| value[0] }

    return old_values_hash.with_indifferent_access
  end

  def new_values_from_event_changes
    event_changes_hash = self.event_changes.to_hash
    new_values_hash = event_changes_hash.merge(event_changes_hash) {|key, value| value[1] }

    return new_values_hash.with_indifferent_access
  end

  def formatted_datetime
    self.created_at.to_s(:event_datetime)
  end

end

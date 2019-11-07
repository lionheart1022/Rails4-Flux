class EventV2 < ActiveRecord::Base
  self.table_name = "events_v2"

  belongs_to :eventable, polymorphic: true
  belongs_to :initiator, polymorphic: true

  validates :label, presence: true
  validates :initiator, presence: true, unless: :custom_initiator_label?

  def initiator_label
    return custom_initiator_label if custom_initiator_label?

    case initiator_type
    when "User"
      initiator.email
    else
      raise "unsupported initiator class"
    end
  end
end

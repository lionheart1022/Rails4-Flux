class EventsAddLinkedObjectFields < ActiveRecord::Migration
  def change
    add_column(:events, :linked_object_type, :string)
    add_column(:events, :linked_object_id, :integer)
  end
end

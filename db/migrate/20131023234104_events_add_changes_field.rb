class EventsAddChangesField < ActiveRecord::Migration
  def change
    add_column(:events, :event_changes, :text)
  end
end

class ChangeTimeToDateTimeOnTrackings < ActiveRecord::Migration
  def change
    remove_column :trackings, :event_time
    remove_column :trackings, :expected_delivery_time

    add_column :trackings, :event_time, :datetime
    add_column :trackings, :expected_delivery_time, :datetime
  end
end

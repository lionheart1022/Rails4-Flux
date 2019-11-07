class PickupsChangeTimeToString < ActiveRecord::Migration
  def change
    change_column(:pickups, :from_time, :string)
    change_column(:pickups, :to_time, :string)
  end
end

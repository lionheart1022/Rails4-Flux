class PickupsAddScopedId < ActiveRecord::Migration
  def change
    add_column(:pickups, :pickup_id, :integer)
  end
end

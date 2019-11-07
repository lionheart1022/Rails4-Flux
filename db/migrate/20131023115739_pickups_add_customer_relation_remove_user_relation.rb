class PickupsAddCustomerRelationRemoveUserRelation < ActiveRecord::Migration
  def up
    add_column(:pickups, :customer_id, :integer)
    remove_column(:pickups, :user_id)
  end

  def down
    add_column(:pickups, :user_id, :integer)
    remove_column(:pickups, :customer_id)
  end
end

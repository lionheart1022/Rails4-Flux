class ShipmentsRemoveUserId < ActiveRecord::Migration
  def up
    remove_column(:shipments, :user_id)
  end

  def down
    add_column(:shipments, :user_id, :integer)
  end
end

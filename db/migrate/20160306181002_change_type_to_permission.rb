class ChangeTypeToPermission < ActiveRecord::Migration
  def up
    rename_column :permissions, :type, :permission
  end

  def down
    rename_column :permissions, :permission, :type
  end
end

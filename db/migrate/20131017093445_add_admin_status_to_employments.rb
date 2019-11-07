class AddAdminStatusToEmployments < ActiveRecord::Migration
  def change
    add_column :employments, :is_admin, :boolean, :default => false
  end
end

class RemoveCustomerAccessMigratedFlag < ActiveRecord::Migration
  def change
    remove_column :users, :customer_access_migrated
  end
end

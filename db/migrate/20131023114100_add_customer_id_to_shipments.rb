class AddCustomerIdToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :customer_id, :integer
  end
end

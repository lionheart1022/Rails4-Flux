class AddAutoPickups < ActiveRecord::Migration
  def change
    add_column :pickups, :auto, :boolean, default: false
    add_column :pickups, :bll, :string, null: true
    add_column :customer_carrier_products, :allow_auto_pickup, :boolean, default: false
    add_column :shipments, :pickup_id, :integer, null: true
  end
end

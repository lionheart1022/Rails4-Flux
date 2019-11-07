class CustomersAddShipmentPickupId < ActiveRecord::Migration
  def change
    add_column(:customers, :current_shipment_id, :integer)
    add_column(:customers, :current_pickup_id, :integer)
  end
end

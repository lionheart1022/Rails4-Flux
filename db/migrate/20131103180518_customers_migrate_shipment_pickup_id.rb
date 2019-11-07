class CustomersMigrateShipmentPickupId < ActiveRecord::Migration
  def change
    Customer.all.each do |customer|
      customer.current_pickup_id    = customer.pickups.count
      customer.current_shipment_id  = customer.shipments.count
      customer.save!
    end
  end
end

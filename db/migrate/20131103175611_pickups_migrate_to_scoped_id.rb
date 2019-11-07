class PickupsMigrateToScopedId < ActiveRecord::Migration
  def change
    Customer.all.each do |customer|
      customer.pickups.order(:id).each_with_index do |pickup, i|
        pickup.pickup_id = i+1
        pickup.save!
      end
    end
  end
end

class PickupsCreateUniquePickupId < ActiveRecord::Migration
  def change
    add_column(:pickups, :unique_pickup_id, :string)

    Customer.order(:id).all.each do |customer|
      customer.pickups.order(:pickup_id).all.each do |pickup|
        pickup.unique_pickup_id = customer.unique_pickup_id(pickup.pickup_id)
        pickup.save!
      end
    end
  end
end

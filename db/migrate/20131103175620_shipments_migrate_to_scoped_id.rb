class ShipmentsMigrateToScopedId < ActiveRecord::Migration
  def change
    Customer.all.each do |customer|
      customer.shipments.order(:id).each_with_index do |shipment, i|
        shipment.shipment_id = i+1
        shipment.save!
      end
    end
  end
end

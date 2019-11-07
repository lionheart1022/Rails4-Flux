class ShipmentsMigrateIdToUniqueId < ActiveRecord::Migration
  def change
    add_column(:shipments, :unique_shipment_id, :string)

    Customer.order(:id).all.each do |customer|
      customer.shipments.order(:shipment_id).all.each do |shipment|
        shipment.unique_shipment_id = customer.unique_shipment_id(shipment.shipment_id)
        shipment.save!
      end
    end
  end
end

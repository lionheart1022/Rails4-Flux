class AddErrorsToShipments < ActiveRecord::Migration
  def change
    add_column(:shipments, :shipment_errors, :text)

    Shipment.all.each do |shipment|
      shipment.shipment_errors = []
      shipment.save!
    end
  end
end

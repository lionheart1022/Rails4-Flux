class ShipmentsSetShipmentTypeToExport < ActiveRecord::Migration
  def change
  	Shipment.all.each do |shipment|
  		shipment.shipment_type = Shipment::ShipmentTypes::EXPORT
  		shipment.save!
  	end
  end
end

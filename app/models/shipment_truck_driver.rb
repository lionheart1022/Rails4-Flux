class ShipmentTruckDriver < ActiveRecord::Base
  belongs_to :shipment, required: true
  belongs_to :truck_driver, required: true
end

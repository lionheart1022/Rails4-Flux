class ShipmentAdditionalSurcharge < ActiveRecord::Base
  belongs_to :shipment, required: true
end

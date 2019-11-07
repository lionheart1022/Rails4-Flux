class ShipmentCollectionItem < ActiveRecord::Base
  belongs_to :shipment_collection, required: true
  belongs_to :shipment, required: true

  scope :selected, -> { where selected: true }
end

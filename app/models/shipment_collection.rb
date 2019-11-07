class ShipmentCollection < ActiveRecord::Base
  has_many :items, class_name: "ShipmentCollectionItem", dependent: :delete_all
  has_many :shipments, through: :items

  def selected_shipment_ids
    items.selected.pluck(:shipment_id)
  end
end

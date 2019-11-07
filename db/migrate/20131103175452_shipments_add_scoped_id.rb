class ShipmentsAddScopedId < ActiveRecord::Migration
  def change
    add_column(:shipments, :shipment_id, :integer)
  end
end

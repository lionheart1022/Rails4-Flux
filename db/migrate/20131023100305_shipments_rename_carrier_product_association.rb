class ShipmentsRenameCarrierProductAssociation < ActiveRecord::Migration
  def change
    rename_column(:shipments, :shipping_product_id, :carrier_product_id)
  end
end

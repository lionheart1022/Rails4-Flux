class AddExternalAwbAssetToShipment < ActiveRecord::Migration
  def change
    add_column :shipments, :external_awb_asset, :string
  end
end

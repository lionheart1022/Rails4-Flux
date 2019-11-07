class AddWarningsToShipment < ActiveRecord::Migration
  def change
  	add_column :shipments, :shipment_warnings, :text
  end
end

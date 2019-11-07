class AddRemarksToShipment < ActiveRecord::Migration
  def change
    add_column :shipments, :remarks, :string
  end
end

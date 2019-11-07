class AddReturnLabelToShipment < ActiveRecord::Migration
  def change
    add_column :shipments, :return_label, :boolean, default: false
  end
end

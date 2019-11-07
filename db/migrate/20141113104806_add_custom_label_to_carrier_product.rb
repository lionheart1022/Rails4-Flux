class AddCustomLabelToCarrierProduct < ActiveRecord::Migration
  def change
    add_column :carrier_products, :custom_label, :boolean, default: false
  end
end

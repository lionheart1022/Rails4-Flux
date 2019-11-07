class AddCustomLabelVariant < ActiveRecord::Migration
  def change
    add_column :carrier_products, :custom_label_variant, :string
  end
end

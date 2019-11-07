class AddProductTagsToCarrierProduct < ActiveRecord::Migration
  def change
    add_column :carrier_products, :options, :text
  end
end

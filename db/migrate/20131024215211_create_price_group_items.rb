class CreatePriceGroupItems < ActiveRecord::Migration
  def change
    create_table :price_group_items do |t|
      t.belongs_to  :price_group
      t.belongs_to  :carrier_product
      t.string      :margin_percentage
      t.timestamps
    end
  end
end

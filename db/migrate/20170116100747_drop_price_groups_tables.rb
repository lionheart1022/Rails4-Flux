class DropPriceGroupsTables < ActiveRecord::Migration
  def change
    drop_table :price_groups
    drop_table :price_group_items
    remove_column :customers, :price_group_id
  end
end

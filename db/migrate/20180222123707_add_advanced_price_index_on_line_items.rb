class AddAdvancedPriceIndexOnLineItems < ActiveRecord::Migration
  def change
    add_index :advanced_price_line_items, :advanced_price_id
  end
end

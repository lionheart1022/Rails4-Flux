class AddTimesToAdvancedPriceLineItems < ActiveRecord::Migration
  def change
    add_column :advanced_price_line_items, :times, :integer, default: 1
  end
end

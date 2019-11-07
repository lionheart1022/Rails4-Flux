class AddExtraPrecisionForAdvancedPriceLineItems < ActiveRecord::Migration
  def up
    change_column :advanced_price_line_items, :cost_price_amount, :decimal, precision: 20, scale: 12
    change_column :advanced_price_line_items, :sales_price_amount, :decimal, precision: 20, scale: 12
  end

  def down
    change_column :advanced_price_line_items, :cost_price_amount, :decimal, precision: 20, scale: 12
    change_column :advanced_price_line_items, :sales_price_amount, :decimal, precision: 20, scale: 12
  end
end

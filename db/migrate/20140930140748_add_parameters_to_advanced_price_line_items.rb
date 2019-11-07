class AddParametersToAdvancedPriceLineItems < ActiveRecord::Migration
  def change
    add_column :advanced_price_line_items, :parameters, :text
  end
end

class AddTypeToPriceLineItem < ActiveRecord::Migration
  def change
    add_column :advanced_price_line_items, :price_type, :string
  end
end

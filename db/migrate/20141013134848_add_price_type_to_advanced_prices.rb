class AddPriceTypeToAdvancedPrices < ActiveRecord::Migration
  def change
    add_column :advanced_prices, :price_type, :string
  end
end

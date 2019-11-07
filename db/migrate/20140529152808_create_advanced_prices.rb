class CreateAdvancedPrices < ActiveRecord::Migration
  def change
    create_table :advanced_prices do |t|
      t.belongs_to  :shipment
      t.string      :cost_price_currency
      t.string      :sales_price_currency
      t.timestamps
    end
  end
end

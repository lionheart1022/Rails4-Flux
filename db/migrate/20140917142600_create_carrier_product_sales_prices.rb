class CreateCarrierProductSalesPrices < ActiveRecord::Migration
  def change
    create_table :carrier_product_sales_prices do |t|
      t.integer :carrier_product_id
      t.integer :sales_price_id

      t.timestamps
    end
  end
end

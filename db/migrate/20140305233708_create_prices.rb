class CreatePrices < ActiveRecord::Migration
  def change
    create_table :prices do |t|
      t.belongs_to  :shipment
      t.belongs_to  :company
      t.decimal     :cost_price_amount, :precision => 8, :scale => 2
      t.string      :cost_price_currency
      t.decimal     :sales_price_amount, :precision => 8, :scale => 2
      t.string      :sales_price_currency
      t.timestamps
    end
  end
end

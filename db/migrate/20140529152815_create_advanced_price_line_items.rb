class CreateAdvancedPriceLineItems < ActiveRecord::Migration
  def change
    create_table :advanced_price_line_items do |t|
      t.belongs_to :advanced_price
      t.string      :description
      t.decimal     :cost_price_amount, :precision => 8, :scale => 2
      t.decimal     :sales_price_amount, :precision => 8, :scale => 2
      t.timestamps
    end
  end
end

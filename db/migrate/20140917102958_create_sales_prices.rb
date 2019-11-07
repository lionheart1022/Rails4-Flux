class CreateSalesPrices < ActiveRecord::Migration
  def change
    create_table :sales_prices do |t|
    	t.integer :company_id
    	t.string :name
    	t.float :margin_percentage
      t.timestamps
    end
  end
end

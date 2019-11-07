class CreateCustomerPriceRelations < ActiveRecord::Migration
  def change
    create_table :customer_price_relations do |t|
      t.integer :sales_price_id
      t.integer :customer_id

      t.timestamps
    end
  end
end

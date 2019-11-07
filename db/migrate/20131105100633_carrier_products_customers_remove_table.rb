class CarrierProductsCustomersRemoveTable < ActiveRecord::Migration
  def up
    drop_table(:carrier_products_customers)
  end

  def down
    create_table "carrier_products_customers", force: true do |t|
      t.integer "customer_id"
      t.integer "carrier_product_id"
    end
  end
end

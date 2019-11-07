class CreateCustomersCarrierProductsLink < ActiveRecord::Migration
  def change
    create_table :carrier_products_customers do |t|
      t.belongs_to :customer
      t.belongs_to :carrier_product
    end
  end
end

class CreateCustomerCarrierProducts < ActiveRecord::Migration
  def change
    create_table :customer_carrier_products do |t|
      t.belongs_to  :customer
      t.belongs_to  :carrier_product
      t.boolean     :is_disabled
      t.timestamps
    end
  end
end

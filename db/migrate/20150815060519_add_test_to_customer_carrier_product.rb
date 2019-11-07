class AddTestToCustomerCarrierProduct < ActiveRecord::Migration
  def change
    add_column :customer_carrier_products, :test, :boolean, default: false
  end
end

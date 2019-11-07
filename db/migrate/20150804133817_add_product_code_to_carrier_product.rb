class AddProductCodeToCarrierProduct < ActiveRecord::Migration
  def change
    add_column :carrier_products, :product_code, :string
  end
end

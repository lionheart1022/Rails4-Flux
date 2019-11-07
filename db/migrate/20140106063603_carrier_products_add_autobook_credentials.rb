class CarrierProductsAddAutobookCredentials < ActiveRecord::Migration
  def change
    add_column :carrier_products, :credentials, :text

    # Add empty credentials to existing carrier products
    CarrierProduct.all.each do |cp|
      cp.set_credentials(credentials: {})
    end
  end
end

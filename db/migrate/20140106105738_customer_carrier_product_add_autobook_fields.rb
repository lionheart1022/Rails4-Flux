class CustomerCarrierProductAddAutobookFields < ActiveRecord::Migration
  def change
    add_column(:customer_carrier_products, :enable_autobooking, :boolean)
    add_column(:customer_carrier_products, :automatically_autobook, :boolean)

    # Migrate existing products to disallow autobooking
    CustomerCarrierProduct.all.each do |cp|
      cp.enable_autobooking = false
      cp.automatically_autobook = false
      cp.save!
    end
  end
end

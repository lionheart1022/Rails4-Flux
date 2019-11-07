class CarrierProductsAddState < ActiveRecord::Migration
  def up
    add_column(:carrier_products, :state, :string)

    CarrierProduct.all.each do |carrier_product|
      owner_chain = carrier_product.owner_carrier_product_chain
      should_mark_as_configured = false
      if owner_chain.count > 0
        if owner_chain.count == 1
          if owner_chain[0] == carrier_product
            should_mark_as_configured = false
          else
            should_mark_as_configured = owner_chain.select {|cp| cp.should_mark_children_as_configured == true }.count > 0
          end
        else
          should_mark_as_configured = owner_chain.select {|cp| cp.should_mark_children_as_configured == true }.count > 0
        end
      end
      if should_mark_as_configured
        carrier_product.state = CarrierProduct::States::LOCKED_FOR_CONFIGURING
      else
        carrier_product.state = CarrierProduct::States::UNLOCKED_FOR_CONFIGURING
      end
      carrier_product.save!
    end
  end

  def down
    remove_column(:carrier_products, :state, :string)
  end
end

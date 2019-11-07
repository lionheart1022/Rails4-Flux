class CarrierProductsRemovePredefined < ActiveRecord::Migration
  def up
    remove_column(:carrier_products, :is_predefined_product)
  end

  def down
    add_column(:carrier_products, :is_predefined_product, :boolean)
  end
end

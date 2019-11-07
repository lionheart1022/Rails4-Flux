class CarrierProductsAddTypeField < ActiveRecord::Migration
  def change
    add_column(:carrier_products, :type, :string)
  end
end

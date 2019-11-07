class DropDeprecatedCarrierProductSurchargesTable < ActiveRecord::Migration
  def change
    drop_table :carrier_product_surcharges
  end
end

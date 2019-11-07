class MigrationFlagOnOldSurcharges < ActiveRecord::Migration
  def change
    add_column :carrier_product_surcharges, :dmig, :boolean
  end
end

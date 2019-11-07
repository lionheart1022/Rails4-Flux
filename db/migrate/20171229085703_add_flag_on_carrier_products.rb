class AddFlagOnCarrierProducts < ActiveRecord::Migration
  def change
    add_column :carrier_products, :flag, :string
  end
end

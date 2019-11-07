class AddTransitTimeOnCarrierProducts < ActiveRecord::Migration
  def change
    add_column :carrier_products, :transit_time, :string
  end
end

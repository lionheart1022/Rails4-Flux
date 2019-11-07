class AddAutomaticTrackingToCarrierProducts < ActiveRecord::Migration
  def change
    add_column :carrier_products, :automatic_tracking, :boolean, default: false
  end
end

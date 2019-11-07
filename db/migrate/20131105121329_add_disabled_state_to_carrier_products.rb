class AddDisabledStateToCarrierProducts < ActiveRecord::Migration
  def change
    add_column :carrier_products, :is_disabled, :boolean, default: false
  end
end

class AddExchangeTypeToCarrierProducts < ActiveRecord::Migration
  def change
    add_column :carrier_products, :exchange_type, :string
  end
end

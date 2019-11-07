class AddResponseFromCarrierToPickups < ActiveRecord::Migration
  def change
    add_column :pickups, :carrier_identifier, :string
    add_column :pickups, :response_from_carrier, :json
  end
end

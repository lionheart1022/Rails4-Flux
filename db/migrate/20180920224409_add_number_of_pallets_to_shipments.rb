class AddNumberOfPalletsToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :number_of_pallets, :integer
  end
end

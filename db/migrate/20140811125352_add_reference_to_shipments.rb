class AddReferenceToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :reference, :string
  end
end

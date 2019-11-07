class AddNoteToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :note, :text
  end
end

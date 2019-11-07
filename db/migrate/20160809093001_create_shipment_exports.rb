class CreateShipmentExports < ActiveRecord::Migration
  def change
    create_table :shipment_exports do |t|
      t.string  :owner_type, null: false
      t.integer :owner_id, null: false
      t.integer :shipment_id, null: false
      t.boolean :exported, default: false
      t.boolean :updated, default: false

      t.timestamps null: false
    end

    add_index :shipment_exports, [:shipment_id, :owner_id, :owner_type], :unique => true, name: :shipment_exports_unique_index
  end
end

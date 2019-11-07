class CreateShipmentExportSettings < ActiveRecord::Migration

  def up
    create_table :shipment_export_settings do |t|
      t.string  :owner_type, null: false
      t.integer :owner_id, null: false

      t.boolean :booked, default: false
      t.boolean :in_transit, default: false
      t.boolean :delivered, default: false
      t.boolean :problem, default: false

      t.timestamps null: false
    end

    add_index :shipment_export_settings, [:owner_id, :owner_type], :unique => true

    Company.all.map do |c|
      ShipmentExportSetting.create(owner_id: c.id, owner_type: c.class.to_s)
    end
  end

  def down
    drop_table :shipment_export_settings
  end

end

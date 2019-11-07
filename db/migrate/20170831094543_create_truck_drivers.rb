class CreateTruckDrivers < ActiveRecord::Migration
  def change
    create_table :truck_drivers do |t|
      t.timestamps null: false
      t.datetime :disabled_at
      t.references :company, null: false
      t.string :name
    end

    create_table :shipment_truck_drivers do |t|
      t.datetime :created_at, null: false
      t.references :shipment, null: false
      t.references :truck_driver, null: false
    end

    change_table :carrier_products do |t|
      t.boolean :truck_driver_enabled, default: false
    end
  end
end

class CreateTablesForTruckFleet < ActiveRecord::Migration
  def change
    create_table :trucks do |t|
      t.timestamps null: false
      t.string :name
      t.datetime :disabled_at
      t.references :company, index: true, foreign_key: true
      t.integer :company_truck_number
      t.integer :current_delivery_number, default: 0
    end

    create_table :deliveries do |t|
      t.string :unique_delivery_number
      t.integer :truck_delivery_number
      t.references :truck, index: true, foreign_key: true
      t.references :company, index: true, foreign_key: true
      t.timestamps null: false
      t.string :state
    end

    add_reference :trucks, :delivery, index: true, foreign_key: true
    add_column :companies, :current_truck_number, :integer, default: 0

    create_join_table :shipments, :deliveries

    # join table between deliveries and truck derivers
    create_table :deliveries_truck_drivers do |t|
      t.references :delivery
      t.references :truck_driver
    end

    # add active delivery id to trucks
    add_column :trucks, :active_delivery_id, :integer, index: true
    add_foreign_key :trucks, :deliveries, column: :active_delivery_id

    add_column :trucks, :default_driver_id, :integer
  end
end

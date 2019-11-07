class CreateFerryBookings < ActiveRecord::Migration
  def change
    add_column :shipments, :ferry_booking_shipment, :boolean, default: false

    create_table :ferry_routes do |t|
      t.timestamps null: false
      t.datetime :disabled_at

      t.references :company, null: false
      t.string :name, null: false
      t.string :port_code_from, null: false
      t.string :port_code_to, null: false
    end

    create_table :ferry_product_integrations do |t|
      t.timestamps null: false

      t.references :company, null: false
      t.json :settings
    end

    create_table :ferry_products do |t|
      t.timestamps
      t.datetime :disabled_at

      t.references :route, null: false
      t.string :time_of_departure, null: false

      t.references :carrier_product
      t.references :integration
      t.json :pricing_schema
    end

    create_table :ferry_bookings do |t|
      t.timestamps null: false

      t.references :shipment, null: false
      t.references :route, null: false
      t.references :product, null: false
      t.string :truck_type
      t.integer :truck_length
      t.string :truck_registration_number
      t.string :trailer_registration_number
      t.boolean :with_driver
      t.integer :cargo_weight
      t.boolean :empty_cargo, null: false, default: false
      t.text :description_of_goods
      t.text :additional_info
    end
  end
end

class CreatePackages < ActiveRecord::Migration
  def change
    add_column :shipments, :tracking_packages, :boolean, default: false, null: false

    create_table :packages do |t|
      t.timestamps null: false
      t.references :shipment, null: false
      t.references :active_recording
      t.string :unique_identifier
      t.json :metadata
    end

    create_table :package_recordings do |t|
      t.datetime :created_at, null: false
      t.references :package, null: false
      t.decimal :weight_value
      t.decimal :volume_weight_value
      t.string :weight_unit
      t.json :fee_data
      t.json :dimensions
    end
  end
end

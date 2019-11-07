class CreateEndOfDayManifests < ActiveRecord::Migration
  def change
    create_table :end_of_day_manifests do |t|
      t.belongs_to :company
      t.belongs_to :customer
      t.timestamps
    end

    create_table :end_of_day_manifests_shipments do |t|
      t.belongs_to :end_of_day_manifest
      t.belongs_to :shipment
    end
  end
end

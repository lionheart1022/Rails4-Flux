class CreateGenericEndOfDayManifestsTable < ActiveRecord::Migration
  def change
    create_table :eod_manifests do |t|
      t.datetime :created_at, null: false
      t.references :created_by
      t.references :owner, polymorphic: true, null: false
      t.integer :owner_scoped_id, null: false
    end

    create_table :eod_manifest_shipments, id: false do |t|
      t.references :manifest, null: false
      t.references :shipment, null: false
    end

    create_table :scoped_counters do |t|
      t.timestamps null: false
      t.references :owner, polymorphic: true, null: false
      t.string :type
      t.string :identifier
      t.integer :value, null: false, default: 0
    end
  end
end

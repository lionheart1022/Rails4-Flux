class AddShipmentExportRuns < ActiveRecord::Migration
  def change
    create_table :shipment_export_runs do |t|
      t.datetime :created_at, null: false
      t.references :owner, polymorphic: true, null: false
      t.text :xml_response
    end
  end
end

class CreateAPIShipmentExportLogs < ActiveRecord::Migration
  def change
    create_table :api_shipment_export_logs do |t|
      t.integer :company_id
      t.json :shipments

      t.timestamps null: false
    end
  end
end

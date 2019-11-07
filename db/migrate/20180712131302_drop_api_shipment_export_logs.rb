class DropAPIShipmentExportLogs < ActiveRecord::Migration
  def change
    drop_table :api_shipment_export_logs
  end
end

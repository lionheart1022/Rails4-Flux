class AddCreatedTriggerOnShipmentExportSettings < ActiveRecord::Migration
  def change
    add_column :shipment_export_settings, :trigger_when_created, :boolean, null: false, default: false
  end
end

class AddCancelledTriggerToExports < ActiveRecord::Migration
  def change
    add_column :shipment_export_settings, :trigger_when_cancelled, :boolean, default: false, null: false
  end
end

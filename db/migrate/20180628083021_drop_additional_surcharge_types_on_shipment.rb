class DropAdditionalSurchargeTypesOnShipment < ActiveRecord::Migration
  def change
    remove_column :shipments, :additional_surcharges
  end
end

class AdditionalSurchargeTypesOnShipment < ActiveRecord::Migration
  def change
    add_column :shipments, :additional_surcharges, :json
  end
end

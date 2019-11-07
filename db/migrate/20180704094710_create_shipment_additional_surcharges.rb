class CreateShipmentAdditionalSurcharges < ActiveRecord::Migration
  def change
    create_table :shipment_additional_surcharges do |t|
      t.references :shipment, null: false
      t.string :surcharge_type
      t.json :surcharge_props
    end
  end
end

class CreateShipmentRequests < ActiveRecord::Migration
  def change
    create_table :shipment_requests do |t|
      t.references :shipment, index: true, foreign_key: true
      t.string :state

      t.timestamps null: false
    end
  end
end

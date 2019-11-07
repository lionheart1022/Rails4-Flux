class CreateCarrierPickupRequests < ActiveRecord::Migration
  def change
    create_table :carrier_pickup_requests do |t|
      t.datetime :created_at, null: false
      t.datetime :handled_at
      t.string :type, null: false
      t.references :pickup, null: false
      t.integer :retries, null: false, default: 0
      t.json :params
      t.json :result
    end
  end
end

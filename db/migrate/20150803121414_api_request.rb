class APIRequest < ActiveRecord::Migration
  def change
    create_table :api_requests do |t|
      t.string  :unique_id
      t.integer :shipment_id
      t.string  :token
      t.string  :callback_url

      t.timestamps null: false
    end
  end
end

class CreateRateSheets < ActiveRecord::Migration
  def change
    create_table :rate_sheets do |t|
      t.datetime :created_at, null: false
      t.references :created_by
      t.references :company, null: false
      t.references :customer_recording, null: false
      t.references :carrier_product, null: false
      t.references :base_price_document_upload, null: false
      t.json :margins
    end
  end
end

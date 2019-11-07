class CreatePriceDocumentUploads < ActiveRecord::Migration
  def change
    create_table :price_document_uploads do |t|
      t.datetime :created_at, null: false
      t.references :created_by
      t.references :company, null: false
      t.references :carrier_product, null: false
      t.string :original_filename
      t.string :s3_object_key
      t.boolean :active, null: false
    end
  end
end

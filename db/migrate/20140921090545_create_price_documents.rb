class CreatePriceDocuments < ActiveRecord::Migration
  def change
  	create_table :price_documents do |t|
  		t.integer :carrier_product_id
  		t.text :document
  	end
  end
end

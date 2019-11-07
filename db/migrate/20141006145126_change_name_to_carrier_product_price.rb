class ChangeNameToCarrierProductPrice < ActiveRecord::Migration
  def change
  	rename_table :price_documents, :carrier_product_prices
  end
end

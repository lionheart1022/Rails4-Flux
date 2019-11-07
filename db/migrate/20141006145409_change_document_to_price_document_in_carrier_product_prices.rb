class ChangeDocumentToPriceDocumentInCarrierProductPrices < ActiveRecord::Migration
  def change
  	rename_column :carrier_product_prices, :document, :price_document
  end
end

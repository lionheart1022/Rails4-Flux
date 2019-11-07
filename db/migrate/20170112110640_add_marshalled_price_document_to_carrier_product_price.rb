class AddMarshalledPriceDocumentToCarrierProductPrice < ActiveRecord::Migration
  def change
    add_column :carrier_product_prices, :marshalled_price_document, :binary
  end
end

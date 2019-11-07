class CreateIndexForShipmentIdOnAdvancedPrices < ActiveRecord::Migration
  def change
    add_index :advanced_prices, :shipment_id
  end
end

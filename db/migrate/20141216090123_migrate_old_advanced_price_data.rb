class MigrateOldAdvancedPriceData < ActiveRecord::Migration
  def up
    add_column :advanced_prices, :seller_id, :integer
    add_column :advanced_prices, :buyer_id, :integer
    add_column :advanced_prices, :seller_type, :string
    add_column :advanced_prices, :buyer_type, :string

    Shipment.all.each do |shipment|
      advanced_price             = shipment.advanced_price

      next unless advanced_price
      advanced_price.seller_id   = shipment.carrier_product.company_id
      advanced_price.seller_type = Company.to_s
      advanced_price.buyer_id    = shipment.customer.id
      advanced_price.buyer_type  = Customer.to_s

      shipment.advanced_prices << advanced_price
      shipment.save!
    end

    remove_column :advanced_prices, :customer_id, :integer
    remove_column :advanced_prices, :company_id, :integer

  end

  def down
    add_column :advanced_prices, :customer_id, :integer
    add_column :advanced_prices, :company_id, :integer

    Shipment.all.each do |shipment|
      advanced_price = shipment.advanced_prices.first

      next unless advanced_price
      advanced_price.company_id  = advanced_price.seller_id
      advanced_price.customer_id = advanced_price.buyer_id

      shipment.advanced_price = advanced_price
      shipment.save!
    end

    remove_column :advanced_prices, :seller_id, :integer
    remove_column :advanced_prices, :buyer_id, :integer
    remove_column :advanced_prices, :seller_type, :string
    remove_column :advanced_prices, :buyer_type, :string
  end
end

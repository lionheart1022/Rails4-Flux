class MigrateOldSalesPriceData < ActiveRecord::Migration
  def up

    sales_prices = SalesPrice.all
    add_column :sales_prices, :reference_id, :integer
    add_column :sales_prices, :reference_type, :string

    sales_prices.each do |sp|
      customers        = sp.customers
      carrier_products = sp.carrier_products

      customers.each do |c|
        carrier_products.each do |cp|

          customer_carrier_product = CustomerCarrierProduct.find_customer_carrier_product(customer_id: c.id, carrier_product_id: cp.id)
          SalesPrice.create_sales_price(reference_id: customer_carrier_product.id, reference_type: CustomerCarrierProduct.to_s, margin_percentage: sp.margin_percentage) if customer_carrier_product
        end
      end
    end

    carrier_products = CarrierProduct.all
    carrier_products.each do |cp|
      SalesPrice.create_sales_price(reference_id: cp.id, reference_type: CarrierProduct.to_s) unless cp.sales_price.present?
    end

    # link new sales price if none are present
    CustomerCarrierProduct.all.each do |ccp|
      SalesPrice.create_sales_price(reference_id: ccp.id, reference_type: CustomerCarrierProduct.to_s) unless ccp.sales_price.present?
    end

    remove_column :sales_prices, :name, :string
    remove_column :sales_prices, :company_id, :integer

    drop_table :carrier_product_sales_prices
    drop_table :customer_price_relations

  end

  def down
    create_table :carrier_product_sales_prices do |t|
      t.integer :carrier_product_id
      t.integer :sales_price_id

      t.timestamps
    end

    create_table :customer_price_relations do |t|
      t.integer :sales_price_id
      t.integer :customer_id

      t.timestamps
    end
    add_column :sales_prices, :name, :string
    add_column :sales_prices, :company_id, :integer

    remove_column :sales_prices, :reference_id, :integer
    remove_column :sales_prices, :reference_type, :string
  end

end

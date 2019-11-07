class MigratePriceDataToNewStructure < ActiveRecord::Migration
  def change

  	shipments = Shipment.all

  	shipments.each do |shipment|

  		unless shipment.prices.empty? || shipment.prices.nil?
  			price      				  = shipment.prices.first
  			
  			cost_price_amount    = price.cost_price_amount
  			cost_price_currency  = price.cost_price_currency
  			sales_price_amount   = price.sales_price_amount
  			sales_price_currency = price.sales_price_currency

  			AdvancedPrice.transaction do
			    shipment.advanced_price = AdvancedPrice.new_advanced_price(
			    	shipment_id:          shipment.id, 
			    	price_type:           'manual', 
			    	cost_price_currency:  cost_price_currency,
			    	sales_price_currency: sales_price_currency
			    )

			    line_item = AdvancedPriceLineItem.create_line_item(
			    	description:        'Manual Price',
			    	cost_price_amount:  cost_price_amount,
			    	sales_price_amount: sales_price_amount
			    )

			    shipment.advanced_price.advanced_price_line_items << line_item
			    shipment.advanced_price.save!
		  	end
  		end

  	end

  end
end

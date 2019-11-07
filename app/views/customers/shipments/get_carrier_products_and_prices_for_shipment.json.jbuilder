json.status "success"
json.html @html
json.data do
  json.carrier_products do
    json.array! @carrier_products_and_prices do |row|
      json.carrier_product_id row[:carrier_product_id]
      json.carrier_product_name row[:carrier_product_name]
      json.price do
        if row[:price]
          json.amount row[:price].total_sales_price_amount.to_s
        else
          nil
        end
      end
    end
  end
end

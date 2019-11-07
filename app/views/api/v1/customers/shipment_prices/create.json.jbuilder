json.array! @price_catalog do |result_item|
  json.name result_item.carrier_product_name
  json.product_code result_item.carrier_product_code
  json.transit_time result_item.carrier_product_transit_time
  json.price_amount result_item.price_amount ? number_with_precision(result_item.price_amount, precision: 2) : nil
  json.price_currency result_item.price_currency
end

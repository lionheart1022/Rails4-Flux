json.ignore_nil!

if @view_model.shipment.present?
  json.id @view_model.shipment.unique_shipment_id
  json.state @view_model.shipment.state
  json.awb @view_model.shipment.awb
  json.awb_link @view_model.shipment.asset_awb && @view_model.shipment.asset_awb.attachment.url
  json.shipping_date @view_model.shipment.shipping_date

  json.description @view_model.shipment.description
  json.reference @view_model.shipment.reference
  json.remarks @view_model.shipment.remarks
  json.delivery_instructions @view_model.shipment.delivery_instructions
  json.carrier_product @view_model.carrier_product.name
  json.parcelshop_id @view_model.shipment.parcelshop_id

  json.dutiable @view_model.shipment.dutiable
  if @view_model.shipment.dutiable
    json.customs_amount @view_model.shipment.customs_amount
    json.customs_currency @view_model.shipment.customs_currency
    json.customs_code @view_model.shipment.customs_code
  end

  if @view_model.advanced_price.present?
    if @view_model.show_detailed_price
      json.cost_price_amount @view_model.advanced_price.total_cost_price_amount
      json.cost_price_currency @view_model.advanced_price.cost_price_currency
      json.sales_price_amount @view_model.advanced_price.total_sales_price_amount
      json.sales_price_currency @view_model.advanced_price.sales_price_currency

      json.price_lines @view_model.advanced_price.advanced_price_line_items.map do |item|
        json.line_description item.description
        json.line_cost_price item.cost_price_amount
        json.line_sales_price item.sales_price_amount
        json.line_quantity item.times
      end
    else
      json.price @view_model.advanced_price.total_sales_price_amount
      json.currency @view_model.advanced_price.sales_price_currency
    end
  end

  @view_model.shipment.as_goods.tap do |goods|
    json.package_dimensions goods.ordered_lines do |line|
      json.height line.height
      json.length line.length
      json.width line.width
      json.weight line.weight
      json.volume_weight line.volume_weight
      json.amount line.quantity
      json.goods_identifier line.goods_identifier
    end
  end

  json.sender do
    json.company_name @view_model.sender.company_name
    json.address_line1 @view_model.sender.address_line1
    json.address_line2 @view_model.sender.address_line2
    json.address_line3 @view_model.sender.address_line3
    json.state_code @view_model.sender.state_code
    json.city @view_model.sender.city
    json.zip_code @view_model.sender.zip_code
    json.country_name @view_model.sender.country_name
    json.country_code @view_model.sender.country_code
    json.phone_number @view_model.sender.phone_number
    json.email @view_model.sender.email
    json.attention @view_model.sender.attention
  end

  json.recipient do
    json.company_name @view_model.recipient.company_name
    json.address_line1 @view_model.recipient.address_line1
    json.address_line2 @view_model.recipient.address_line2
    json.address_line3 @view_model.recipient.address_line3
    json.state_code @view_model.recipient.state_code
    json.city @view_model.recipient.city
    json.zip_code @view_model.recipient.zip_code
    json.country_name @view_model.recipient.country_name
    json.country_code @view_model.recipient.country_code
    json.phone_number @view_model.recipient.phone_number
    json.email @view_model.recipient.email
    json.attention @view_model.recipient.attention
  end

else
  json.error @view_model.not_found_text
end


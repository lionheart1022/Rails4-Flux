json.shipments @update_result.shipments do |shipment|
  json.shipment_id shipment[:shipment_id]
  json.awb shipment[:awb]
  json.state shipment[:state]
end

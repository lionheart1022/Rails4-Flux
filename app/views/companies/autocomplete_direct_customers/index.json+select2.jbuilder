json.results @customers do |customer|
  json.id customer.id
  json.text customer.name
  json.shipmentRequestPriceURL companies_customer_scoped_shipment_request_prices_path(selected_customer_identifier: customer.id)
  json.address do
    json.extract!(
      customer.address,
      :company_name,
      :attention,
      :email,
      :phone_number,
      :address_line1,
      :address_line2,
      :address_line3,
      :zip_code,
      :city,
      :country_code,
      :country_name,
      :state_code,
      :state_name,
    )
  end
end

json.pagination do
  json.more @customers.next_page.present?
end

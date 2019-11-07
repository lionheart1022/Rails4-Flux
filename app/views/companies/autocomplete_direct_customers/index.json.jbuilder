json.array! @customers do |customer|
  json.id customer.id
  json.url companies_customer_path(customer)
  json.text customer.name
  json.address do
    json.extract!(customer.address,
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
      :state_name
    )
  end
end

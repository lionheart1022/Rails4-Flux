json.name current_company.name

if company_address = current_company.address
  json.phone_number company_address.phone_number.presence
  json.email company_address.email.presence
else
  json.phone_number nil
  json.email nil
end

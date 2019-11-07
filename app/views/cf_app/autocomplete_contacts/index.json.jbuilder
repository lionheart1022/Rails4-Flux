json.array! @contacts do |contact|
  json.id contact.id
  json.url url_for(controller: "contacts", action: "show", id: contact.id)
  json.label contact.company_name
  json.text contact.company_name
  json.value do
    json.extract!(contact,
      :company_name,
      :attention,
      :email,
      :residential,
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

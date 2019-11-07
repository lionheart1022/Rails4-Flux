json.results @contacts do |contact|
  json.id contact.id
  json.text contact.company_name
  json.url url_for(controller: "contacts", action: "show", id: contact.id)
end

json.pagination do
  json.more @contacts.next_page.present?
end

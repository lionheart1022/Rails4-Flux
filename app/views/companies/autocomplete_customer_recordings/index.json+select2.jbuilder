json.results @customer_recordings do |customer_recording|
  json.id customer_recording.id
  json.text customer_recording.customer_name
  json.url build_path_for_customer_recording(customer_recording)
end

json.pagination do
  json.more @customer_recordings.next_page.present?
end

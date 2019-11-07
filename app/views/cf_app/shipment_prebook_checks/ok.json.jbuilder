if @prebook_check.estimated_arrival_date
  json.type "confirmation"
  json.title "Confirm estimated arrival date"
  json.html_content render(partial: "cf_app/shipment_prebook_checks/ok_estimated_arrival_date_content", formats: [:html])
else
  json.type "continue"
end

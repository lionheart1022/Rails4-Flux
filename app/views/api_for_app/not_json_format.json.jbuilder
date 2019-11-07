json.message "Only JSON responses are supported - not '.#{params[:format]}'"
json.help do
  json.try_url url_for(format: "json", only_path: false)
end

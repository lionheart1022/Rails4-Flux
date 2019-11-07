json.message "No format was specified - adding .json to the path of the request URL should be sufficient"
json.help do
  json.try_url url_for(format: "json", only_path: false)
end

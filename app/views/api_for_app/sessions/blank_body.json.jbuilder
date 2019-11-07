json.error "The expected 'email' and 'password' properties are not set"
json.help do
  json.example_body do
    json.email "test@example.com"
    json.password "password"
  end
end

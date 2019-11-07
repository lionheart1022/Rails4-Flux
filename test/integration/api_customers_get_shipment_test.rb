require "test_helper"

class APICustomersGetShipmentTest < ActionDispatch::IntegrationTest
  test "can get a shipment successfully" do
    company = FactoryBot.create(:company)
    customer = FactoryBot.create(:customer, company: company)
    access_token = AccessToken.create!(owner: customer, value: SecureRandom.hex)

    shipment = FactoryBot.create(:shipment, unique_shipment_id: "1-1-1", company: company, customer: customer, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))

    get "/api/v1/customers/shipments/#{shipment.unique_shipment_id}", { "Content-Type" => "application/json" }, { "Access-Token" => access_token.value }

    assert_equal 200, status

    json_response = JSON.parse(response.body)
    refute json_response["error"], "Unexpected error response: #{response.body}"
  end
end

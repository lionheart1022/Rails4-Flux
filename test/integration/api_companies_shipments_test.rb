require "test_helper"

class APICompaniesShipmentsTest < ActionDispatch::IntegrationTest
  def test_index
    company_a = FactoryBot.create(:company)
    company_b = FactoryBot.create(:company)

    carrier_x = FactoryBot.create(:carrier, company: company_a)
    carrier_x_product_1 = FactoryBot.create(:carrier_product, carrier: carrier_x, company: company_a)

    access_token = AccessToken.create!(owner: company_a, value: SecureRandom.hex)

    FactoryBot.create(:shipment, company: company_a, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient), carrier_product: carrier_x_product_1)
    FactoryBot.create(:shipment, company: company_a, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient), carrier_product: carrier_x_product_1)
    FactoryBot.create(:shipment, company: company_b, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient))

    get "/api/v1/companies/shipments.xml", access_token: access_token.value

    assert_equal 200, status

    xml = Nokogiri::XML(response.body)

    assert_equal 2, xml.xpath("//Shipment").count
  end

  def test_index_without_format
    company = FactoryBot.create(:company)
    access_token = AccessToken.create!(owner: company, value: SecureRandom.hex)

    assert_raise ActionController::UnknownFormat do
      get "/api/v1/companies/shipments", { access_token: access_token.value }
    end
  end

  def test_index_with_json_format
    company = FactoryBot.create(:company)
    access_token = AccessToken.create!(owner: company, value: SecureRandom.hex)

    assert_raise ActionController::UnknownFormat do
      get "/api/v1/companies/shipments", { access_token: access_token.value }, { "Accept" => "application/json" }
    end
  end

  def test_show
    company = FactoryBot.create(:company)
    access_token = AccessToken.create!(owner: company, value: SecureRandom.hex)

    carrier = FactoryBot.create(:carrier, company: company)
    carrier_product = FactoryBot.create(:carrier_product, carrier: carrier, company: company)
    shipment = FactoryBot.create(:shipment, company: company, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient), carrier_product: carrier_product, unique_shipment_id: "1-1-1")

    get "/api/v1/companies/shipments/#{shipment.unique_shipment_id}", access_token: access_token.value

    json_body = JSON.parse(response.body)

    assert_equal 200, status
    assert_equal "1-1-1", json_body["id"]
  end

  def test_show_not_found
    company = FactoryBot.create(:company)
    access_token = AccessToken.create!(owner: company, value: SecureRandom.hex)

    get "/api/v1/companies/shipments/a-b-c", access_token: access_token.value

    json_body = JSON.parse(response.body)

    assert_equal 200, status
    refute json_body["id"]
    assert json_body["error"]
  end

  def test_show_with_json_format
    company = FactoryBot.create(:company)
    access_token = AccessToken.create!(owner: company, value: SecureRandom.hex)

    carrier = FactoryBot.create(:carrier, company: company)
    carrier_product = FactoryBot.create(:carrier_product, carrier: carrier, company: company)
    shipment = FactoryBot.create(:shipment, company: company, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient), carrier_product: carrier_product, unique_shipment_id: "1-1-1")

    get "/api/v1/companies/shipments/#{shipment.unique_shipment_id}", { access_token: access_token.value }, { "Accept" => "application/json" }

    json_body = JSON.parse(response.body)

    assert_equal 200, status
    assert_equal "1-1-1", json_body["id"]
  end

  def test_show_with_xml_format
    company = FactoryBot.create(:company)
    access_token = AccessToken.create!(owner: company, value: SecureRandom.hex)

    carrier = FactoryBot.create(:carrier, company: company)
    carrier_product = FactoryBot.create(:carrier_product, carrier: carrier, company: company)
    shipment = FactoryBot.create(:shipment, company: company, sender: FactoryBot.create(:sender), recipient: FactoryBot.create(:recipient), carrier_product: carrier_product, unique_shipment_id: "1-1-1")

    assert_raise ActionController::UnknownFormat do
      get "/api/v1/companies/shipments/#{shipment.unique_shipment_id}.xml", access_token: access_token.value
    end
  end
end

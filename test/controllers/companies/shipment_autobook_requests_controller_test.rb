require "test_helper"

module Companies
  class ShipmentAutobookRequestsControllerTest < ActionController::TestCase
    include Devise::TestHelpers

    test "show to product owner" do
      company = ::Company.create!(name: "Company")
      customer = ::Customer.create!(name: "Customer", company: company)
      user = ::User.create!(company: company, email: "user@example.com", password: "password", confirmed_at: Time.now)
      sign_in user

      carrier = Carrier.create!(company: company, name: "Carrier")
      carrier_product = CarrierProduct.create!(company: company, carrier: carrier, name: "Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      shipment = FactoryBot.create(:shipment, carrier_product: carrier_product, company: company, customer: customer)
      autobook_request = CarrierProductAutobookRequest.create_carrier_product_autobook_request(company_id: company.id, customer_id: customer.id, shipment_id: shipment.id)

      get :show, shipment_id: shipment.id, id: autobook_request.id

      assert_response :success
    end

    test "show to product owner when product is sold to another company" do
      company = FactoryBot.create(:company)
      carrier = FactoryBot.create(:carrier)
      carrier_product = CarrierProduct.create!(company: company, carrier: carrier, name: "Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

      company_x = FactoryBot.create(:company)
      customer = FactoryBot.create(:customer, company: company_x)
      carrier_x = FactoryBot.create(:carrier, company: company_x)
      carrier_product_x = CarrierProduct.create!(carrier_product: carrier_product, carrier: carrier_x, company: company, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)

      user = ::User.create!(company: company, email: "user@example.com", password: "password", confirmed_at: Time.now)
      sign_in user

      shipment = FactoryBot.create(:shipment, carrier_product: carrier_product_x, company: company_x, customer: customer)
      autobook_request = CarrierProductAutobookRequest.create_carrier_product_autobook_request(company_id: company_x.id, customer_id: customer.id, shipment_id: shipment.id)
      autobook_request.update!(info: "First line\nSecond line\n")

      get :show, shipment_id: shipment.id, id: autobook_request.id

      assert_response :success
    end

    test "do not show to product buyer" do
      company = FactoryBot.create(:company)
      carrier = FactoryBot.create(:carrier)
      carrier_product = CarrierProduct.create!(company: company, carrier: carrier, name: "Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)

      company_x = FactoryBot.create(:company)
      customer = FactoryBot.create(:customer, company: company_x)
      carrier_x = FactoryBot.create(:carrier, company: company_x)
      carrier_product_x = CarrierProduct.create!(carrier_product: carrier_product, carrier: carrier_x, company: company, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)

      user = ::User.create!(company: company_x, email: "user@example.com", password: "password", confirmed_at: Time.now)
      sign_in user

      shipment = FactoryBot.create(:shipment, carrier_product: carrier_product_x, company: company_x, customer: customer)
      autobook_request = CarrierProductAutobookRequest.create_carrier_product_autobook_request(company_id: company_x.id, customer_id: customer.id, shipment_id: shipment.id)

      assert_raises "ActiveRecord::RecordNotFound" do
        get :show, shipment_id: shipment.id, id: autobook_request.id
      end
    end
  end
end

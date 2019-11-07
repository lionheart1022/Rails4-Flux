require "test_helper"

class Customers::EndOfDayManifestsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "new" do
    company = ::Company.create!(name: "A Company")
    customer = ::Customer.create!(name: "A Customer", company: company)
    user = ::User.create!(email: "user@example.com", password: "password", confirmed_at: Time.now)
    ::UserCustomerAccess.create!(user: user, customer: customer, company: company)
    sign_in user

    get :new, current_customer_identifier: customer.id

    assert_response :success
  end
end

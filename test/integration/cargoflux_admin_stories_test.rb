require "test_helper"

class CargofluxAdminStoriesTest < ActionDispatch::IntegrationTest
  test "log in to regular company" do
    Company.create_cargoflux_company!(name: "CargoFlux ApS", current_customer_id: 0, current_report_id: 0)
    @company_a = Company.create_direct_company!(name: "Company A", current_customer_id: 0, current_report_id: 0)

    @user_regular_password = "otherTestingpass"
    @user_regular = User.create!(company_id: @company_a.id, email: "admin-a@example.com", password: @user_regular_password, is_admin: true, confirmed_at: Time.now)

    get "/users/sign_in"
    assert_equal 200, status

    post "/users/sign_in", user: { email: @user_regular.email, password: @user_regular_password }
    follow_redirect!
    assert_equal 200, status
    assert_equal "/companies/dashboard", path
  end
end

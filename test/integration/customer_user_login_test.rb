require "test_helper"

class CustomerUserLoginTest < ActionDispatch::IntegrationTest
  test "migrated customer user is redirected to customer shipments page upon successful login" do
    @company_a = Company.create!(name: "Company A", current_customer_id: 0, current_report_id: 0)
    @customer_a1 = Customer.create!(name: "Customer A.1", company: @company_a, current_shipment_id: 0, current_pickup_id: 0, current_end_of_day_manifest_id: 0, customer_id: "1")
    @user_password = "otherTestingpass"
    @user = User.create!(company_id: @company_a.id, customer_id: nil, is_admin: false, is_customer: true, email: "admin-a@example.com", password: @user_password, confirmed_at: Time.now)
    UserCustomerAccess.create!(company: @company_a, customer: @customer_a1, user: @user)

    post "/users/sign_in", user: { email: @user.email, password: @user_password }
    follow_redirect!

    assert_equal 200, status
    assert_equal "/customers/#{@customer_a1.id}/shipments", path
  end

  test "user is redirected to account selector when both customer and company user" do
    @company_a = Company.create!(name: "Company A", current_customer_id: 0, current_report_id: 0)
    @customer_a1 = Customer.create!(name: "Customer A.1", company: @company_a, current_shipment_id: 0, current_pickup_id: 0, current_end_of_day_manifest_id: 0, customer_id: "1")
    @customer_a2 = Customer.create!(name: "Customer A.2", company: @company_a, current_shipment_id: 0, current_pickup_id: 0, current_end_of_day_manifest_id: 0, customer_id: "2")
    @user_password = "otherTestingpass"
    @user = User.create!(company_id: @company_a.id, customer_id: nil, is_admin: false, is_customer: false, email: "admin-a@example.com", password: @user_password, confirmed_at: Time.now)
    UserCustomerAccess.create!(company: @company_a, customer: @customer_a1, user: @user)
    UserCustomerAccess.create!(company: @company_a, customer: @customer_a2, user: @user)

    post "/users/sign_in", user: { email: @user.email, password: @user_password }
    follow_redirect!

    assert_equal 200, status
    assert_equal "/select-account", path
    assert_match %r{/customers/#{@customer_a1.id}/shipments}, body, "Expected link to customer"
    assert_match %r{/companies/dashboard}, body, "Expected link to company"
  end
end

require "test_helper"

class RootPagesTest < ActionDispatch::IntegrationTest
  test "does not redirect when domain not related to company" do
    company = Company.create!(name: "TEST-A", domain: "test-a.example.com")

    host! "test-b.example.com"

    get "/"
    assert_equal 200, status
  end

  test "redirect to log in for domain related to company" do
    company = Company.create!(name: "TEST-A", domain: "test-a.example.com")

    host! company.domain

    get "/"
    assert_redirected_to "http://#{company.domain}/users/sign_in"
  end

  test "redirect to admin root for domain related to company for logged in user" do
    company = Company.create!(name: "TEST-A", domain: "test-a.example.com")
    user_password = "testingpass"
    user = User.create!(company_id: company.id, email: "user@example.com", password: user_password, is_admin: true, confirmed_at: Time.now)

    host! company.domain

    post "/users/sign_in", user: { email: user.email, password: user_password }
    follow_redirect!
    assert_equal "/companies/dashboard", path

    # Go back to root
    get "/"
    assert_redirected_to "http://#{company.domain}/admin"
  end
end

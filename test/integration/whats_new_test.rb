require "test_helper"

class WhatsNewTest < ActionDispatch::IntegrationTest
  test "page works" do
    company = Company.create!(name: "TEST-A")
    user_password = "testingpass"
    user = User.create!(company_id: company.id, email: "user@example.com", password: user_password, is_admin: true, confirmed_at: Time.now)

    post "/users/sign_in", user: { email: user.email, password: user_password }

    get "/companies/whats_new"

    assert_equal 200, status
  end
end

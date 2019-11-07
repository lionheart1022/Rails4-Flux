require "test_helper"

class Customers::CreatePickupTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "run" do
    company = ::Company.create!(name: "Test Company", initials: "TEST")
    customer = ::Customer.create!(name: "Test Customer", company: company, customer_id: 1)

    company_user = User.new(
      email: "test@example.com",
      password: "password",
      confirmed_at: Time.now,
      company: company,
      is_customer: false,
    )
    company_user.build_email_settings
    company_user.save!

    pickup_data = {
      pickup_date: Date.today,
      from_time: "12:00",
      to_time: "15:00",
      description: nil,
    }

    contact_data = {
      company_name: "Test Customer",
      attention: nil,
      address_line1: "Njalsgade 17A",
      address_line2: nil,
      address_line3: nil,
      zip_code: "2300",
      city: "Copenhagen",
      country_code: "DK",
    }

    pickup = nil
    assert_emails 1 do
      pickup = customer.create_pickup(pickup_data.merge(:contact_attributes => contact_data))
    end

    assert pickup.present?
    assert pickup.persisted?

    assert_match /Pickup created/i, ActionMailer::Base.deliveries.last.subject
  end
end

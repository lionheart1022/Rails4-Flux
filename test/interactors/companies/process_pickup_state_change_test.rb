require "test_helper"

class Companies::ProcessPickupStateChangeTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @company = ::Company.create!(name: "Test Company", initials: "TEST")

    @company_user = User.new(
      email: "test-company-user@example.com",
      password: "password",
      confirmed_at: Time.now,
      company: @company,
      is_customer: false,
    )
    @company_user.build_email_settings
    @company_user.save!

    @customer = ::Customer.create!(name: "Test Customer", company: @company, customer_id: 1)

    @customer_user = User.new(
      email: "test-customer-user@example.com",
      password: "password",
      confirmed_at: Time.now,
      company: @company,
      customer: nil,
      is_customer: true,
    )
    @customer_user.build_email_settings
    @customer_user.save!

    UserCustomerAccess.create!(company: @company, customer: @customer, user: @customer_user)
  end

  test "run with book event" do
    pickup = create_pickup

    assert_emails 1 do
      run_interactor(pickup, event: Pickup::Events::BOOK)
    end

    assert_match /Pickup booked/i, ActionMailer::Base.deliveries.last.subject
  end

  test "run with pickup event" do
    pickup = create_pickup

    assert_emails 1 do
      run_interactor(pickup, event: Pickup::Events::PICKUP)
    end

    assert_match /Pickup picked up/i, ActionMailer::Base.deliveries.last.subject
  end

  test "run with report problem event" do
    pickup = create_pickup

    assert_emails 1 do
      run_interactor(pickup, event: Pickup::Events::REPORT_PROBLEM)
    end

    assert_match /Pickup problem/i, ActionMailer::Base.deliveries.last.subject
  end

  test "run with cancel event" do
    pickup = create_pickup

    assert_emails 1 do
      run_interactor(pickup, event: Pickup::Events::CANCEL)
    end

    assert_match /Pickup cancelled/i, ActionMailer::Base.deliveries.last.subject
  end

  private

  def create_pickup
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

    Pickup.create_pickup(
      customer_id: @customer.id,
      scoped_customer_id: @customer.customer_id,
      company_id: @company.id,
      pickup_data: pickup_data,
      contact_data: contact_data,
      id_generator: @customer,
    )
  end

  def run_interactor(pickup, event: nil, comment: nil)
    interactor = Companies::ProcessPickupStateChange.new(company: @company, pickup: pickup)
    interactor.state = Companies::ProcessPickupStateChange::STATE_EVENT_MAPPING.key(event)
    interactor.comment = comment

    interactor.perform!
  end
end

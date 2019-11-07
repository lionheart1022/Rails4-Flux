require "test_helper"

class Customers::CancelShipmentTest < ActiveSupport::TestCase
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
      customer: @customer,
      is_customer: true,
    )
    @customer_user.build_email_settings
    @customer_user.save!
  end

  test "that customer is not notified" do
    shipment = FactoryBot.build(:shipment)
    shipment.company = @company
    shipment.customer = @customer
    shipment.sender = Sender.new(
      company_name: "Cargoflux ApS",
      attention: "",
      address_line1: "Njalsgade 17A",
      address_line2: "",
      address_line3: "",
      zip_code: "2300",
      city: "Copenahgen",
      country_code: "DK",
      country_name: "Denmark",
      state_code: "",
      phone_number: "",
      email: "",
      save_sender_in_address_book: false,
    )
    shipment.recipient = Recipient.new(
      company_name: "",
      attention: "Some Person",
      address_line1: "Some Address 123",
      address_line2: "",
      address_line3: "",
      zip_code: "2300",
      city: "Copenhagen",
      country_code: "DK",
      country_name: "Denmark",
      state_code: "",
      phone_number: "",
      email: "",
      save_recipient_in_address_book: false,
    )
    shipment.save

    interactor = Customers::Shipments::CancelShipment.new(
      company_id: shipment.company_id,
      customer_id: shipment.customer_id,
      shipment_id: shipment.id,
    )

    result = nil
    assert_emails 0 do
      result = interactor.run
    end

    assert result.try(:error).blank?, "Interactor should not return error"
  end
end

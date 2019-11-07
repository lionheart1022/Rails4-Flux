require "test_helper"

class FerryBookingNotificationManagerTest < ActiveSupport::TestCase
  test "notifications when booked" do
    company = Company.create!(name: "Company")
    customer = Customer.create!(company: company, name: "Customer")
    carrier_product = CarrierProduct.create!(name: "Product")
    shipment = Shipment.create!(shipping_date: Date.today, number_of_packages: 1, carrier_product: carrier_product, company: company, customer: customer)
    ferry_route = FerryRoute.create!(company: company, name: "Route", port_code_from: "F", port_code_to: "T", destination_address: Contact.new)
    ferry_product = FerryProduct.create!(route: ferry_route, time_of_departure: "10:00")
    ferry_booking = FerryBooking.create!(shipment: shipment, route: ferry_route, product: ferry_product)

    User.create!(company: shipment.company, is_customer: false, email: "company-user@example.com", password: "password", confirmed_at: Time.zone.now).tap do |user|
      user.create_email_settings(ferry_booking_booked: true)
    end

    User.create!(company: nil, email: "customer-user-1@example.com", password: "password", confirmed_at: Time.zone.now).tap do |user|
      UserCustomerAccess.create!(company: company, customer: customer, user: user)
      user.create_email_settings(ferry_booking_booked: true)
    end

    User.create!(company: nil, email: "customer-user-2@example.com", password: "password", confirmed_at: Time.zone.now).tap do |user|
      UserCustomerAccess.create!(company: company, customer: customer, user: user)
      user.create_email_settings(ferry_booking_booked: false)
    end

    deliveries_before = ActionMailer::Base.deliveries.dup

    FerryBookingNotificationManager.handle_event_now(shipment, event: Shipment::Events::BOOK)

    deliveries_after = ActionMailer::Base.deliveries.dup

    deliveries = deliveries_after - deliveries_before

    assert_equal 2, deliveries.count
    assert_equal Set.new(["company-user@example.com", "customer-user-1@example.com"]), Set.new(deliveries.map { |mail| mail["to"].value })
  end

  test "notifications when failed" do
    company = Company.create!(name: "Company")
    customer = Customer.create!(company: company, name: "Customer")
    carrier_product = CarrierProduct.create!(name: "Product")
    shipment = Shipment.create!(shipping_date: Date.today, number_of_packages: 1, carrier_product: carrier_product, company: company, customer: customer)
    ferry_route = FerryRoute.create!(company: company, name: "Route", port_code_from: "F", port_code_to: "T", destination_address: Contact.new)
    ferry_product = FerryProduct.create!(route: ferry_route, time_of_departure: "10:00")
    ferry_booking = FerryBooking.create!(shipment: shipment, route: ferry_route, product: ferry_product)

    User.create!(company: shipment.company, is_customer: false, email: "company-user@example.com", password: "password", confirmed_at: Time.zone.now).tap do |user|
      user.create_email_settings(ferry_booking_failed: true)
    end

    User.create!(company: nil, email: "customer-user-1@example.com", password: "password", confirmed_at: Time.zone.now).tap do |user|
      UserCustomerAccess.create!(company: company, customer: customer, user: user)
      user.create_email_settings!(ferry_booking_failed: true)
    end

    User.create!(company: nil, email: "customer-user-2@example.com", password: "password", confirmed_at: Time.zone.now).tap do |user|
      UserCustomerAccess.create!(company: company, customer: customer, user: user, revoked_at: Time.zone.now)
      user.create_email_settings!(ferry_booking_failed: true)
    end

    User.create!(company: nil, email: "customer-user-3@example.com", password: "password", confirmed_at: Time.zone.now).tap do |user|
      UserCustomerAccess.create!(company: company, customer: customer, user: user)
      user.create_email_settings!(ferry_booking_failed: true)
    end

    deliveries_before = ActionMailer::Base.deliveries.dup

    FerryBookingNotificationManager.handle_event_now(shipment, event: Shipment::Events::REPORT_PROBLEM)

    deliveries_after = ActionMailer::Base.deliveries.dup

    deliveries = deliveries_after - deliveries_before

    assert_equal 3, deliveries.count
    assert_equal Set.new(["company-user@example.com", "customer-user-1@example.com", "customer-user-3@example.com"]), Set.new(deliveries.map { |mail| mail["to"].value })
  end
end

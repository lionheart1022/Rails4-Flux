class FerryBookingMailer < ApplicationMailer
  def booked_notification(user:, customer:, company:, shipment:, ferry_booking:)
    @user = user
    @customer = customer
    @company = company
    @shipment = shipment
    @ferry_booking = ferry_booking

    mail(
      from: company.info_email.presence || ActionMailer::Base.default[:from],
      to: user.email,
      subject: "#{customer.name} - Ferry booking successfully booked",
    )
  end

  def booked_customer_notification(user:, customer:, company:, shipment:, ferry_booking:)
    @user = user
    @customer = customer
    @company = company
    @shipment = shipment
    @ferry_booking = ferry_booking

    mail(
      from: company.info_email.presence || ActionMailer::Base.default[:from],
      to: user.email,
      subject: "#{company.name} - Ferry booking successfully booked",
    )
  end

  def failed_notification(user:, customer:, company:, shipment:, ferry_booking:)
    @user = user
    @customer = customer
    @company = company
    @shipment = shipment
    @ferry_booking = ferry_booking

    mail(
      from: company.info_email.presence || ActionMailer::Base.default[:from],
      to: user.email,
      subject: "#{customer.name} - Ferry booking failed",
    )
  end

  def failed_customer_notification(user:, customer:, company:, shipment:, ferry_booking:)
    @user = user
    @customer = customer
    @company = company
    @shipment = shipment
    @ferry_booking = ferry_booking

    mail(
      from: company.info_email.presence || ActionMailer::Base.default[:from],
      to: user.email,
      subject: "#{company.name} - Ferry booking failed",
    )
  end
end

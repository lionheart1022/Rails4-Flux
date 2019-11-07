class FerryBookingNotificationManager
  class << self
    def handle_event(event: nil, event_arguments: nil)
      FerryBookingNotificationJob.perform_later(event_arguments[:shipment_id], event)
    end

    def handle_event_now(shipment, event: nil)
      case event
      when Shipment::Events::BOOK
        new(shipment).send_booked_notifications
      when Shipment::Events::REPORT_PROBLEM
        new(shipment).send_failed_notifications
      end
    end
  end

  attr_reader :shipment, :ferry_booking

  def initialize(shipment)
    @shipment = shipment
    @ferry_booking = FerryBooking.find_by_shipment_id!(shipment.id)
  end

  def send_booked_notifications
    notify_company_users_with(email_setting: :ferry_booking_booked).each do |user|
      FerryBookingMailer.booked_notification(user: user, customer: shipment.customer, company: shipment.company, shipment: shipment, ferry_booking: ferry_booking).deliver_now
    end

    notify_customer_users_with(email_setting: :ferry_booking_booked).each do |user|
      FerryBookingMailer.booked_customer_notification(user: user, customer: shipment.customer, company: shipment.company, shipment: shipment, ferry_booking: ferry_booking).deliver_now
    end
  end

  def send_failed_notifications
    notify_company_users_with(email_setting: :ferry_booking_failed).each do |user|
      FerryBookingMailer.failed_notification(user: user, customer: shipment.customer, company: shipment.company, shipment: shipment, ferry_booking: ferry_booking).deliver_now
    end

    notify_customer_users_with(email_setting: :ferry_booking_failed).each do |user|
      FerryBookingMailer.failed_customer_notification(user: user, customer: shipment.customer, company: shipment.company, shipment: shipment, ferry_booking: ferry_booking).deliver_now
    end
  end

  private

  def notify_company_users_with(email_setting:)
    User
      .where(company_id: shipment.company_id, is_customer: false)
      .includes(:email_settings)
      .where(email_settings: { email_setting => true })
  end

  def notify_customer_users_with(email_setting:)
    User
      .where(id: UserCustomerAccess.active.where(company_id: shipment.company_id, customer_id: shipment.customer_id).select(:user_id))
      .includes(:email_settings)
      .where(email_settings: { email_setting => true })
  end
end

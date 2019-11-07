class ShipmentRequestNotificationManager
  class << self
    def handle_event(shipment_request, event: nil)
      ShipmentRequestNotificationJob.perform_later(shipment_request.id, event)
    end

    def handle_event_now(shipment_request, event: nil)
      case event
      when ShipmentRequest::Events::CREATE
        new(shipment_request).created_notification
      when ShipmentRequest::Events::PROPOSE
        new(shipment_request).proposed_notification
      when ShipmentRequest::Events::ACCEPT
        new(shipment_request).accepted_notification
      when ShipmentRequest::Events::DECLINE
        new(shipment_request).declined_notification
      when ShipmentRequest::Events::BOOK
        new(shipment_request).booked_notification
      when ShipmentRequest::ContextEvents::CUSTOMER_CANCEL
        new(shipment_request).customer_canceled_notification
      when ShipmentRequest::ContextEvents::COMPANY_CANCEL
        new(shipment_request).company_canceled_notification
      end
    end
  end

  attr_reader :shipment_request

  def initialize(shipment_request)
    @shipment_request = shipment_request
  end

  def shipment
    shipment_request.shipment
  end

  def customer
    shipment.customer
  end

  def company
    shipment.company
  end

  def created_notification
    company_users.each do |user|
      ShipmentRequestMailer.shipment_request_created_email(user: user, customer: customer, company: company, shipment: shipment, shipment_request: shipment_request).deliver_now
    end
  end

  def proposed_notification
    customer_users.each do |user|
      ShipmentRequestMailer.shipment_request_proposed_email(user: user, customer: customer, company: company, shipment: shipment, shipment_request: shipment_request).deliver_now
    end
  end

  def accepted_notification
    company_users.each do |user|
      ShipmentRequestMailer.shipment_request_accepted_email(user: user, customer: customer, company: company, shipment: shipment, shipment_request: shipment_request).deliver_now
    end
  end

  def declined_notification
    company_users.each do |user|
      ShipmentRequestMailer.shipment_request_declined_email(user: user, customer: customer, company: company, shipment: shipment, shipment_request: shipment_request).deliver_now
    end
  end

  def booked_notification
    customer_users.each do |user|
      ShipmentRequestMailer.shipment_request_booked_email(user: user, customer: customer, company: company, shipment: shipment, shipment_request: shipment_request).deliver_now
    end
  end

  def customer_canceled_notification
    company_users.each do |user|
      ShipmentRequestMailer.shipment_request_canceled_email(user: user, customer: customer, company: company, is_customer: true, shipment: shipment, shipment_request: shipment_request).deliver_now
    end
  end

  def company_canceled_notification
    customer_users.each do |user|
      ShipmentRequestMailer.shipment_request_canceled_email(user: user, customer: customer, company: company, is_customer: false, shipment: shipment, shipment_request: shipment_request).deliver_now
    end
  end

  def company_users
    Company.all_users(company_id: shipment.company_id)
  end

  def customer_users
    User.where(id: UserCustomerAccess.active.where(company_id: shipment.company_id, customer_id: shipment.customer_id).select(:user_id))
  end
end

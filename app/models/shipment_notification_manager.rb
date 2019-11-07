class ShipmentNotificationManager < SimpleDelegator
  class << self
    def handle_event(event: nil, event_arguments: nil)
      ShipmentNotificationJob.perform_later(event_arguments[:shipment_id], event)
    end

    def handle_event_now(shipment, event: nil)
      case event
      when Shipment::Events::CREATE
        new(shipment).created_notification
      when Shipment::Events::BOOK
        new(shipment).booked_notification
      when Shipment::Events::AUTOBOOK, Shipment::Events::RETRY_AWB_DOCUMENT, Shipment::Events::RETRY_CONSIGNMENT_NOTE
        new(shipment).autobooked_notification
      when Shipment::Events::AUTOBOOK_WITH_WARNINGS
        new(shipment).autobooked_with_warnings_notification
      when Shipment::Events::SHIP
        new(shipment).shipped_notification
      when Shipment::Events::DELIVERED_AT_DESTINATION
        new(shipment).delivered_notification
      when Shipment::Events::REPORT_PROBLEM
        new(shipment).problem_reported_notification
      when Shipment::Events::REPORT_AUTOBOOK_PROBLEM
        new(shipment).autobook_problem_reported_notification
      when Shipment::Events::REPORT_AUTOBOOK_AWB_PROBLEM
        new(shipment).autobook_awb_problem_reported_notification
      when Shipment::Events::REPORT_AUTOBOOK_CONSIGNMENT_NOTE_PROBLEM
        new(shipment).autobook_consignment_note_problem_reported_notification
      when Shipment::Events::CANCEL
        new(shipment).cancelled_notification
      when Shipment::Events::COMMENT
        new(shipment).commented_notification
      when Shipment::Events::RETRY
        new(shipment).retried_notification
      end
    end
  end

  def commented_notification
    customer_users.each do |user|
      ShipmentMailer.shipment_commented_email(user: user, customer: customer, company: company, shipment: shipment).deliver_now
    end
  end

  def cancelled_notification
    customer_users.each do |user|
      ShipmentMailer.shipment_cancelled_email(user: user, customer: customer, company: company, shipment: shipment).deliver_now
    end
  end

  def problem_reported_notification
    customer_users.each do |user|
      ShipmentMailer.shipment_problem_reported_email(user: user, customer: customer, company: company, shipment: shipment).deliver_now
    end
  end

  def autobook_problem_reported_notification
    product_responsible_company_users.each do |user|
      ShipmentMailer.shipment_autobook_problem_reported_email(user: user, customer: customer, company: product_responsible, shipment: shipment).deliver_now
    end

    customer_responsible_company_users.each do |user|
      ShipmentMailer.shipment_autobook_problem_reported_email(user: user, customer: customer, company: customer_responsible, shipment: shipment).deliver_now
    end

    customer_users.each do |user|
      ShipmentMailer.shipment_problem_reported_email(user: user, customer: customer, company: customer_responsible, shipment: shipment).deliver_now
    end
  end

  def autobook_awb_problem_reported_notification
    technical_responsible_company_users.each do |user|
      ShipmentMailer.shipment_autobook_problem_reported_email(user: user, customer: customer, company: technical_responsible, shipment: shipment).deliver_now
    end
  end

  def autobook_consignment_note_problem_reported_notification
    technical_responsible_company_users.each do |user|
      ShipmentMailer.shipment_autobook_problem_reported_email(user: user, customer: customer, company: technical_responsible, shipment: shipment).deliver_now
    end
  end

  def delivered_notification
    customer_users.each do |user|
      ShipmentMailer.shipment_delivered_email(user: user, customer: customer, company: company, shipment: shipment).deliver_now
    end
  end

  def shipped_notification
    customer_users.each do |user|
      ShipmentMailer.shipment_shipped_email(user: user, customer: customer, company: company, shipment: shipment).deliver_now
    end
  end

  def booked_notification
    customer_users.each do |user|
      ShipmentMailer.shipment_booked_email(user: user, customer: customer, company: company, shipment: shipment).deliver_now
    end
  end

  def autobooked_notification
    product_responsible_company_users.each do |user|
      ShipmentMailer.shipment_autobooked_email(user: user, customer: customer, company: product_responsible, shipment: shipment).deliver_now
    end

    customer_responsible_company_users.each do |user|
      ShipmentMailer.shipment_autobooked_email(user: user, customer: customer, company: customer_responsible, shipment: shipment).deliver_now
    end

    customer_users.each do |user|
      ShipmentMailer.shipment_booked_email(user: user, customer: customer, company: customer_responsible, shipment: shipment).deliver_now
    end
  end

  def autobooked_with_warnings_notification
    product_responsible_company_users.each do |user|
      ShipmentMailer.shipment_autobooked_with_warnings_email(user: user, customer: customer, company: product_responsible, shipment: shipment).deliver_now
    end

    customer_responsible_company_users.each do |user|
      ShipmentMailer.shipment_autobooked_with_warnings_email(user: user, customer: customer, company: customer_responsible, shipment: shipment).deliver_now
    end

    customer_users.each do |user|
      ShipmentMailer.shipment_booked_with_warnings_email(user: user, customer: customer, company: customer_responsible, shipment: shipment).deliver_now
    end
  end

  def created_notification
    product_responsible_company_users.each do |user|
      ShipmentMailer.shipment_created_email(user: user, customer: customer, company: company, shipment: shipment).deliver_now
    end
  end

  def retried_notification
    # TODO: This type of notification is usually not triggered but I have seen it at times in staging.
    # For now we will just report it to our exception monitoring service - but we should look into either
    # adding the missing mailer method or get rid of this method.
    ExceptionMonitoring.report_message("ShipmentMailer#shipment_retried_email does not exist", context: { shipment_id: id })
    return

    product_responsible_company_users.each do |user|
      ShipmentMailer.shipment_retried_email(user: user, customer: customer, company: company, shipment: shipment).deliver_now
    end
  end

  def shipment
    __getobj__
  end

  def customer_users
    User.where(id: UserCustomerAccess.active.where(company_id: company_id, customer_id: customer_id).select(:user_id))
  end

  def product_responsible_company_users
    Company.all_users(company_id: product_responsible.id)
  end

  def customer_responsible_company_users(exclude_product_responsible = true)
    if exclude_product_responsible
      if product_responsible == customer_responsible
        return User.none
      end
    end

    Company.all_users(company_id: customer_responsible.id)
  end

  def technical_responsible_company_users
    Company.all_users(company_id: technical_responsible.id)
  end
end

class PickupNotificationManager
  class << self
    def handle_event(pickup, event: nil)
      PickupNotificationJob.perform_later(pickup.id, event)
    end

    def handle_event_now(pickup, event: nil)
      case event
      when Pickup::Events::CREATE
        new(pickup).created_notification
      when Pickup::Events::BOOK
        new(pickup).booked_notification
      when Pickup::Events::PICKUP
        new(pickup).picked_up_notification
      when Pickup::Events::REPORT_PROBLEM
        new(pickup).problem_reported_notification
      when Pickup::Events::CANCEL
        new(pickup).cancelled_notification
      end
    end
  end

  attr_reader :pickup

  def initialize(pickup)
    @pickup = pickup
  end

  def created_notification
    company_users.each do |user|
      PickupMailer.pickup_created_email(user: user, customer: customer, company: company, pickup: pickup).deliver_now
    end
  end

  def booked_notification
    customer_users.each do |user|
      PickupMailer.pickup_booked_email(user: user, customer: customer, company: company, pickup: pickup).deliver_now
    end
  end

  def picked_up_notification
    customer_users.each do |user|
      PickupMailer.pickup_picked_up_email(user: user, customer: customer, company: company, pickup: pickup).deliver_now
    end
  end

  def problem_reported_notification
    customer_users.each do |user|
      PickupMailer.pickup_problem_reported_email(user: user, customer: customer, company: company, pickup: pickup).deliver_now
    end
  end

  def cancelled_notification
    customer_users.each do |user|
      PickupMailer.pickup_cancelled_email(user: user, customer: customer, company: company, pickup: pickup).deliver_now
    end
  end

  def customer
    pickup.customer
  end

  def company
    pickup.company
  end

  def company_users
    Company.all_users(company_id: pickup.company_id)
  end

  def customer_users
    User.where(id: UserCustomerAccess.active.where(company_id: pickup.company_id, customer_id: pickup.customer_id).select(:user_id))
  end
end

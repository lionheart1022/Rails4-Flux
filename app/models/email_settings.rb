class EmailSettings < ActiveRecord::Base
  FLAG_ATTRIBUTES = %w(
    autobook_with_warnings
    book
    cancel
    comment
    create
    delivered
    pickup_book
    pickup_cancel
    pickup_comment
    pickup_create
    pickup_pickup
    pickup_problem
    problem
    rfq_accept
    rfq_book
    rfq_cancel
    rfq_create
    rfq_decline
    rfq_propose
    ship
    ferry_booking_booked
    ferry_booking_failed
  )

  FLAG_ATTRIBUTES_FOR_COMPANY_USER = %w(
    create
    book
    autobook_with_warnings
    ship
    delivered
    problem
    cancel
    comment
    ferry_booking_booked
    ferry_booking_failed
    rfq_create
    rfq_accept
    rfq_decline
    rfq_cancel
    pickup_create
  )

  FLAG_ATTRIBUTES_FOR_CUSTOMER_USER = %w(
    book
    autobook_with_warnings
    ship
    delivered
    problem
    cancel
    comment
    ferry_booking_booked
    ferry_booking_failed
    rfq_propose
    rfq_book
    rfq_cancel
    pickup_book
    pickup_pickup
    pickup_problem
    pickup_cancel
  )

  belongs_to :user

  validates_presence_of :user
  validates_uniqueness_of :user

  class << self
    def build_with_all_unset(attributes = {})
      instance = new(Hash[FLAG_ATTRIBUTES.map { |attr| [attr, false] }])
      instance.assign_attributes(attributes)
      instance
    end

    def build_with_all_set(attributes = {})
      instance = new(Hash[FLAG_ATTRIBUTES.map { |attr| [attr, true] }])
      instance.assign_attributes(attributes)
      instance
    end
  end

  def disable_all_notifications!
    update!(Hash[FLAG_ATTRIBUTES.map { |attr| [attr, false] }])
  end

  def disable_notification_setting!(flag_name)
    set_notification_setting!(flag_name, false)
  end

  def enable_notification_setting!(flag_name)
    set_notification_setting!(flag_name, true)
  end

  def set_notification_setting!(flag_name, value)
    if FLAG_ATTRIBUTES.include?(flag_name.to_s)
      update!(flag_name => value)
    end
  end
end

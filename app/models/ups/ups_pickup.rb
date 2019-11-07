class UPSPickup
  include ActiveModel::Model

  RECORD_ATTRIBUTES = %w(
    pickup_date
    from_time
    to_time
    description
  )

  CONTACT_ATTRIBUTES = %w(
    company_name
    attention
    address_line1
    address_line2
    address_line3
    phone_number
    zip_code
    city
    country_code
  )

  attr_accessor :company, :customer
  attr_accessor :pickup_date
  attr_accessor :from_time, :to_time
  attr_accessor :description
  attr_accessor :company_name
  attr_accessor :attention
  attr_accessor :address_line1
  attr_accessor :address_line2
  attr_accessor :address_line3
  attr_accessor :phone_number
  attr_accessor :zip_code
  attr_accessor :city
  attr_accessor :country_code
  attr_accessor :confirmation_step
  alias_method :confirmation_step?, :confirmation_step

  attr_reader :record
  attr_reader :request

  validates! :company, :customer, presence: true
  validates :pickup_date, presence: true
  validates :from_time, :to_time, presence: true
  validates :company_name, :attention, :city, :phone_number, :country_code, presence: true
  validate :request_can_be_setup, unless: :confirmation_step?

  def save_and_enqueue_request!
    self.record = build_record
    self.request = build_booking_request
    request.setup_params

    if valid?
      Pickup.transaction do
        record.pickup_id = customer.update_next_pickup_id
        record.unique_pickup_id = "#{customer.id}-#{customer.customer_id}-#{record.pickup_id}"
        record.state = Pickup::States::CREATED
        record.save!

        request.save!

        record.events.create!(
          company_id: company.id,
          customer_id: customer.id,
          event_type: Pickup::Events::CREATE,
          description: "UPS pickup",
        )
      end

      CarrierPickupRequestJob.perform_later(request.id)

      true
    else
      raise "Validation error"
    end
  end

  def can_confirm?
    self.record = build_record
    self.request = build_booking_request
    request.setup_params

    self.confirmation_step = true
    return false if invalid?

    self.confirmation_step = false
    valid?
  end

  def matching_shipment_count
    self.request ||= build_booking_request
    request.matching_shipment_count
  end

  def build_contact_from_customer
    CONTACT_ATTRIBUTES.each do |attr|
      self.public_send("#{attr}=", customer.address.public_send(attr))
    end
  end

  def pickup_date_year=(year)
    self.pickup_date ||= Date.today.beginning_of_month
    self.pickup_date = self.pickup_date.change(year: Integer(year))
  end

  def pickup_date_month=(month)
    self.pickup_date ||= Date.today.beginning_of_month
    self.pickup_date = self.pickup_date.change(month: Integer(month))
  end

  def pickup_date_day=(day)
    self.pickup_date ||= Date.today.beginning_of_month
    self.pickup_date = self.pickup_date.change(day: Integer(day))
  end

  alias_method :"pickup_date(1i)=", :pickup_date_year=
  alias_method :"pickup_date(2i)=", :pickup_date_month=
  alias_method :"pickup_date(3i)=", :pickup_date_day=

  private

  attr_writer :record
  attr_writer :request

  def build_record
    pickup = Pickup.new(record_attributes)
    pickup.company = company
    pickup.customer = customer
    pickup.auto = true
    pickup.build_contact(record_contact_attributes)
    pickup
  end

  def build_booking_request
    record ? UPSPickupBookingRequest.new(pickup: record) : nil
  end

  def record_attributes
    Hash[
      RECORD_ATTRIBUTES.map do |attr|
        [attr.to_sym, self.public_send(attr)]
      end
    ]
  end

  def record_contact_attributes
    attrs =
      Hash[
        CONTACT_ATTRIBUTES.map do |attr|
          [attr.to_sym, self.public_send(attr)]
        end
      ]

    attrs[:country_name] = Country.find_country_by_alpha2(country_code).try(:name) if attrs[:country_code].present?

    attrs
  end

  private

  def request_can_be_setup
    raise "`request` needs to be set" unless request

    if request.invalid?
      request.errors.full_messages.each do |error|
        errors.add(:base, error)
      end
    end
  end
end

class FerryBookingForm
  include ActiveModel::Model

  TRUE_STRING_VALUES = %w{1 true}.freeze

  class << self
    def edit_shipment(shipment)
      ferry_booking = FerryBooking.find_by_shipment_id(shipment.id)

      new(
        customer_id: shipment.customer_id,
        route_id: ferry_booking.route_id,
        travel_date: shipment.shipping_date,
        travel_time: ferry_booking.product.time_of_departure,
        truck_type: ferry_booking.truck_type,
        truck_length: ferry_booking.truck_length,
        truck_registration_number: ferry_booking.truck_registration_number,
        trailer_registration_number: ferry_booking.trailer_registration_number,
        with_driver: ferry_booking.with_driver,
        cargo_weight: ferry_booking.cargo_weight,
        empty_cargo: ferry_booking.empty_cargo,
        description_of_goods: ferry_booking.description_of_goods,
        additional_info: ferry_booking.additional_info,
        reference: shipment.reference,
      )
    end
  end

  attr_accessor :company_id
  attr_accessor :customer_id
  attr_accessor :customer_selectable

  attr_accessor :route_id
  attr_accessor :travel_date
  attr_accessor :travel_date_year, :travel_date_month, :travel_date_day
  attr_accessor :travel_time

  attr_accessor :truck_type
  attr_accessor :truck_length
  attr_accessor :truck_registration_number
  attr_accessor :trailer_registration_number
  attr_accessor :with_driver

  attr_accessor :cargo_weight
  attr_accessor :empty_cargo
  attr_accessor :description_of_goods
  attr_accessor :additional_info
  attr_accessor :reference

  alias_method :customer_selectable?, :customer_selectable
  alias_method :"travel_date(1i)=", :travel_date_year=
  alias_method :"travel_date(2i)=", :travel_date_month=
  alias_method :"travel_date(3i)=", :travel_date_day=

  validates :company_id, presence: true
  validates :customer_id, presence: true
  validates :route_id, presence: true
  validates :travel_time, presence: true
  validates :truck_type, presence: true
  validates :truck_length, numericality: { only_integer: true }, presence: true
  validates :cargo_weight, numericality: { only_integer: true }, presence: true, unless: :empty_cargo?
  validate :with_driver_must_be_disabled_for_trailer
  validate :travel_date_must_be_valid

  def initialize(params = {})
    # Defaults
    self.with_driver = true
    self.empty_cargo = false

    super(params)
  end

  def for_company(company)
    self.company_id = company.id
    self.in_company_context = true
    self.in_customer_context = false
    self.customer_selectable = true
  end

  def for_customer(customer)
    self.customer_id = customer.id
    self.company_id = customer.company_id
    self.in_company_context = false
    self.in_customer_context = true
    self.customer_selectable = false
  end

  def assign_attributes(attributes)
    attributes.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def attributes_for_record
    return {} if invalid?

    {
      route_id: route_id,
      truck_type: truck_type,
      truck_length: truck_length_i,
      truck_registration_number: truck_registration_number,
      trailer_registration_number: trailer_registration_number,
      with_driver: with_driver,
      cargo_weight: cargo_weight_i,
      empty_cargo: empty_cargo,
      description_of_goods: description_of_goods,
      additional_info: additional_info,
    }
  end

  def with_driver=(value)
    @with_driver = TRUE_STRING_VALUES.include?(value.to_s)
  end

  alias_method :with_driver?, :with_driver

  def cargo_weight_i
    return nil if cargo_weight.nil?

    begin
      Integer(cargo_weight)
    rescue ArgumentError
      nil
    end
  end

  def truck_length_i
    return nil if truck_length.nil?

    begin
      Integer(truck_length)
    rescue ArgumentError
      nil
    end
  end

  def empty_cargo=(value)
    @empty_cargo = TRUE_STRING_VALUES.include?(value.to_s)
  end

  alias_method :empty_cargo?, :empty_cargo

  def truck_length_in_cm
    if l = truck_length_i
      l * 100 # truck length is in meters
    end
  end

  def travel_date
    if @travel_date
      @travel_date
    elsif travel_date_parts_are_present?
      begin
        new_travel_date_from_parts
      rescue ArgumentError
        nil
      end
    end
  end

  def package_dimensions
    PackageDimensions.new(
      dimensions: [PackageDimension.new(weight: empty_cargo? ? 0.0 : Float(cargo_weight_i), length: truck_length_in_cm, height: 0.0, width: 0.0)],
      volume_type: PackageDimensions::VolumeTypes::VOLUME_WEIGHT,
    )
  end

  def truck_type_options
    [
      ["Cargo Car", "cargo_car"],
      ["Lorry", "lorry"],
      ["Trailer", "trailer"],
    ]
  end

  def truck_type_default_lengths
    {
      "cargo_car" => 5,
      "lorry" => 17,
      "trailer" => 17,
    }
  end

  def available_routes
    if in_company_context?
      FerryRoute.for_company(Company.find(company_id))
    elsif in_customer_context?
      # TODO: Could filter by customer here
      FerryRoute.for_company(Company.find(company_id))
    end
  end

  def travel_time_options
    (0..23).flat_map do |i|
      [
        sprintf("%02d:00", i),
        sprintf("%02d:15", i),
        sprintf("%02d:30", i),
        sprintf("%02d:45", i),
      ]
    end
  end

  def route_departure_times_map
    Hash[available_routes.map { |route| [route.id, route.ordered_active_products.pluck(:time_of_departure)] }]
  end

  def truck_type_trailer?
    truck_type == "trailer"
  end

  private

  attr_accessor :in_company_context, :in_customer_context
  alias_method :in_company_context?, :in_company_context
  alias_method :in_customer_context?, :in_customer_context

  def new_travel_date_from_parts
    Date.new(travel_date_year.to_i, travel_date_month.to_i, travel_date_day.to_i)
  end

  def travel_date_parts_are_present?
    travel_date_year.present? && travel_date_month.present? && travel_date_day.present?
  end

  def with_driver_must_be_disabled_for_trailer
    errors.add(:with_driver, "Cannot be enabled when truck type is trailer") if with_driver? && truck_type_trailer?
  end

  def travel_date_must_be_valid
    return if @travel_date

    unless travel_date_parts_are_present?
      errors.add(:travel_date, :blank)
      return
    end

    begin
      new_travel_date_from_parts
    rescue ArgumentError
      errors.add(:base, "The selected travel date (#{travel_date_year}-#{travel_date_month}-#{travel_date_day}) is not valid.")
    end
  end
end

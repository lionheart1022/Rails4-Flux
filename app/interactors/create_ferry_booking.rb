class CreateFerryBooking
  class BaseError < StandardError; end
  class NoFerryProduct < BaseError; end
  class NoCarrierProductOnFerryProduct < BaseError; end
  class NoCarrierProduct < BaseError; end
  class NoCustomer < BaseError; end

  attr_reader :form
  attr_reader :context
  attr_reader :ferry_product, :carrier_product, :customer
  attr_reader :ferry_booking_record

  def initialize(form:, context:)
    self.form = form
    self.context = context
  end

  def perform!
    return false if form.invalid?

    begin
      set_ferry_product!
      set_carrier_product!
      set_customer!
    rescue NoFerryProduct
      form.errors.add(:travel_time, "This time is not available for the selected route")
      return false
    rescue NoCarrierProductOnFerryProduct
      form.errors.add(:route_id, context.ferry_booking_no_carrier_product_on_ferry_product_error)
      return false
    rescue NoCarrierProduct
      form.errors.add(:route_id, context.ferry_booking_no_carrier_product_error(carrier_product_name: ferry_product.carrier_product.name))
      return false
    end

    FerryBooking.transaction do
      self.ferry_booking_record = FerryBooking.new(form.attributes_for_record)
      ferry_booking_record.product = ferry_product
      ferry_booking_record.build_shipment(
        company_id: form.company_id,
        customer_id: form.customer_id,
        shipment_id: scoped_shipment_id,
        unique_shipment_id: unique_shipment_id,
        state: Shipment::States::WAITING_FOR_BOOKING,
        reference: form.reference,
        shipping_date: form.travel_date,
        number_of_packages: 1,
        package_dimensions: form.package_dimensions,
        carrier_product_id: carrier_product.id,
        sender: sender,
        recipient: recipient,
        ferry_booking_shipment: true,
      )
      ferry_booking_record.save_and_register_create!(initiator: context.initiator)
    end

    FerryBookingEventManager.handle_event(event: Shipment::Events::CREATE, event_arguments: { shipment_id: shipment_record.id })

    true
  end

  def success?
    ferry_booking_record && ferry_booking_record.persisted?
  end

  def shipment_record
    if ferry_booking_record
      ferry_booking_record.shipment
    end
  end

  private

  attr_writer :form
  attr_writer :context
  attr_writer :ferry_booking_record

  def set_ferry_product!
    @ferry_product =
      FerryProduct
      .active
      .joins(:route)
      .where(route_id: form.route_id, time_of_departure: form.travel_time)
      .where(ferry_routes: { company_id: form.company_id })
      .first

    if @ferry_product.nil?
      raise NoFerryProduct, "ferry product not found"
    end

    if @ferry_product.carrier_product.nil?
      raise NoCarrierProductOnFerryProduct, "carrier product missing on ferry product"
    end

    @ferry_product
  end

  def set_carrier_product!
    customer_carrier_product = CustomerCarrierProduct.where(is_disabled: false).find_customer_carrier_product(customer_id: form.customer_id, carrier_product_id: ferry_product.carrier_product_id)
    @carrier_product = customer_carrier_product.try(:carrier_product)

    if @carrier_product.nil?
      raise NoCarrierProduct, "carrier product not found"
    end

    @carrier_product
  end

  def set_customer!
    @customer = Customer.find_company_customer(company_id: form.company_id, customer_id: form.customer_id)

    if @customer.nil?
      raise NoCustomer, "customer not found"
    end

    @customer
  end

  def sender
    customer.address.copy_as_sender
  end

  def recipient
    ferry_product.route.destination_address_as_recipient
  end

  def unique_shipment_id
    "#{customer.id}-#{customer.customer_id}-#{scoped_shipment_id}"
  end

  def scoped_shipment_id
    @scoped_shipment_id ||= customer.update_next_shipment_id
  end
end

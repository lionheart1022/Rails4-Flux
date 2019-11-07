class UpdateFerryBooking
  class BaseError < StandardError; end
  class NoFerryProduct < BaseError; end
  class NoCarrierProductOnFerryProduct < BaseError; end
  class NoCarrierProduct < BaseError; end

  attr_reader :form
  attr_reader :context
  attr_reader :ferry_product, :carrier_product
  attr_reader :shipment_record, :ferry_booking_record

  def initialize(shipment:, form:, context:)
    self.shipment_record = shipment
    self.ferry_booking_record = FerryBooking.find_by_shipment_id(shipment.id)
    self.form = form
    self.context = context
  end

  def perform!
    return false if form.invalid?

    begin
      set_ferry_product!
      set_carrier_product!
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
      ferry_booking_attributes = form.attributes_for_record
      ferry_booking_attributes[:product] = ferry_product

      shipment_attributes = {
        shipping_date: form.travel_date,
        package_dimensions: form.package_dimensions,
        carrier_product_id: carrier_product.id,
        recipient: recipient,
        state: Shipment::States::WAITING_FOR_BOOKING,
        reference: form.reference,
      }

      ferry_booking_record.save_and_register_update!(
        ferry_booking_attributes: ferry_booking_attributes,
        shipment_attributes: shipment_attributes,
        initiator: context.initiator,
      )
    end

    true
  end

  def success?
    form.errors.count == 0
  end

  private

  attr_writer :form
  attr_writer :context
  attr_writer :shipment_record, :ferry_booking_record

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

  def recipient
    ferry_product.route.destination_address_as_recipient
  end
end

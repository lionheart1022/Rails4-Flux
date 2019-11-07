class FerryBookingView
  attr_reader :shipment, :ferry_booking
  attr_reader :customer_name
  attr_accessor :seller, :buyer

  delegate :unique_shipment_id, to: :shipment
  delegate :shipping_date, to: :shipment
  delegate :reference, to: :shipment
  delegate :state, to: :shipment, prefix: true
  delegate :truck_length, :truck_registration_number, :trailer_registration_number, :with_driver?, :description_of_goods, :empty_cargo?, :additional_info, :editable?, :in_progress?, :additional_info_from_response, to: :ferry_booking

  def initialize(shipment)
    @shipment = shipment
    @ferry_booking = FerryBooking.find_by_shipment_id(shipment.id)
  end

  def show_customer_name(customer_name)
    @show_customer_name = true
    @customer_name = customer_name
  end

  def show_customer_name?
    @show_customer_name
  end

  def events
    ferry_booking.events.order(created_at: :desc)
  end

  def carrier_product_name
    shipment.carrier_product.name
  end

  def advanced_price
    if seller
      shipment.advanced_prices.where(seller: seller).first
    elsif buyer
      shipment.advanced_prices.where(buyer: buyer).first
    end
  end

  def price_with_currency
    if advanced_price && advanced_price.advanced_price_line_items.length > 0
      "#{advanced_price.sales_price_currency} #{advanced_price.total_sales_price_amount.round(2)}"
    else
      "N/A"
    end
  end

  def formatted_cargo_weight
    if empty_cargo?
      nil
    else
      "#{ferry_booking.cargo_weight} kg"
    end
  end

  def waybill
    shipment.awb
  end

  def route_name
    "#{ferry_booking.route.name} #{ferry_booking.product.time_of_departure}"
  end

  def show_price?
    true
  end

  def truck_type
    case ferry_booking.truck_type
    when "cargo_car"
      "Cargo Car"
    when "lorry"
      "Lorry"
    when "lorry_and_trailer"
      "Lorry (+ Trailer)"
    when "trailer"
      "Trailer"
    end
  end
end

# As the name of the class implies we want to find a better way of doing this -
# when we get the time.
#
# The role of this class is to take the original price document object and
# modify/contort it by adding appropriate surcharges.

class PriceDocumentContortion
  # Construct new `PriceDocumentContortion` object.
  #
  # It is important that the `price_document` is allowed to be mutated.
  # Meaning, you should pass in a "fresh" price document object.
  def initialize(
    price_document:,
    carrier_product:,
    shipping_date:,
    include_surcharge_types: nil
  )
    @price_document = price_document
    @carrier_product = carrier_product
    @shipping_date = shipping_date
    @include_surcharge_types = Array(include_surcharge_types)
  end

  class << self
    def build_price_document_with_surcharges(*args)
      new(*args).build_price_document_with_surcharges
    end
  end

  def build_price_document_with_surcharges
    add_surcharges_to_price_document!

    price_document
  end

  private

  def add_surcharges_to_price_document!
    surcharges.each do |surcharge|
      price_document.zone_prices.each do |zone_price|
        case
        when surcharge.price_percentage?
          zone_price.charges << price_document_class::RelativeCharge.new(
            identifier: "surcharge",
            name: surcharge.description,
            type: surcharge.calculation_method,
            percentage: surcharge.charge_value_as_numeric,
          )
        when surcharge.price_fixed?
          zone_price.charges << price_document_class::FlatCharge.new(
            identifier: "surcharge",
            name: surcharge.description,
            type: surcharge.calculation_method,
            amount: surcharge.charge_value_as_numeric,
          )
        end
      end
    end
  end

  def surcharges
    carrier_product
      .list_all_surcharges
      .select { |surcharge_on_product| surcharge_on_product.enabled? && surcharge_on_product.parent.enabled? }
      .map { |surcharge_on_product| surcharge_on_product.persisted? ? surcharge_on_product : surcharge_on_product.parent }
      .map { |surcharge_owner| surcharge_owner.active_surcharge(now: parsed_shipping_date) }
      .select { |surcharge|
        if surcharge.nil? || surcharge.charge_value.blank?
          false
        elsif surcharge.default_surcharge?
          true
        elsif include_surcharge_types.present?
          include_surcharge_types.include?(surcharge.type)
        else
          false
        end
      }
  end

  def price_document_class
    price_document.class
  end

  def parsed_shipping_date
    return Time.zone.now if shipping_date.blank?

    if shipping_date.is_a?(Date)
      shipping_date.to_time.beginning_of_day
    elsif shipping_date.is_a?(String)
      Time.zone.parse(shipping_date)
    else
      shipping_date
    end
  end

  attr_reader :price_document
  attr_reader :carrier_product
  attr_reader :shipping_date
  attr_reader :include_surcharge_types
end

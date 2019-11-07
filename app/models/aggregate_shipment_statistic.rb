class AggregateShipmentStatistic < ActiveRecord::Base
  class << self
    def register_changed_shipment(shipment)
      AggregateShipmentStatisticChange.create!(shipment: shipment)
    end

    def process_changed_shipments
      AggregateShipmentStatisticChange.process_changes
    end

    def refresh
      self.needs_refresh.each(&:refresh_monthly)
    end

    def process_change_for_shipment(shipment)
      create_monthly_for_shipment(shipment)
    end

    def create_monthly_for_shipment(shipment)
      shipment_utc_date = shipment.created_at.utc.to_date
      utc_from = shipment_utc_date.beginning_of_month
      utc_to = shipment_utc_date.end_of_month

      base_stats = monthly.where(utc_from: utc_from, utc_to: utc_to)

      customer_stats = base_stats.where(
        carrier_product_id: shipment.carrier_product.id,
        carrier_product_type: shipment.carrier_product.type,
        company_id: shipment.carrier_product.company_id,
        customer_id: shipment.customer_id,
        carrier_id: shipment.carrier_product.carrier_id,
        carrier_type: shipment.carrier_product.carrier.type,
      )

      if customer_stats.empty?
        customer_stats.create!(needs_refresh: true).cascade_customer_statistics!
      else
        customer_stats.update_all(needs_refresh: true)
        customer_stats.each(&:cascade_customer_statistics!)
      end

      next_carrier_product = shipment.carrier_product
      while next_carrier_product.carrier_product do
        company_customer_stats = base_stats.where(
          carrier_product_id: next_carrier_product.id,
          carrier_product_type: next_carrier_product.type,
          company_id: next_carrier_product.carrier_product.company_id,
          company_customer_id: next_carrier_product.company_id,
          carrier_id: next_carrier_product.carrier_id,
          carrier_type: next_carrier_product.carrier.type,
        )

        if company_customer_stats.empty?
          company_customer_stats.create!(needs_refresh: true).cascade_company_customer_statistics!
        else
          company_customer_stats.update_all(needs_refresh: true)
          company_customer_stats.each(&:cascade_company_customer_statistics!)
        end

        next_carrier_product = next_carrier_product.carrier_product
      end

      # This will effectively refresh all (monthly) stats for the given month.
      # By doing this we also handle the case of when a carrier product is changed on a shipment without having to track the before and after states.
      monthly
        .where("utc_from >= :utc_from AND utc_to <= :utc_to", utc_from: utc_from, utc_to: utc_to)
        .update_all(needs_refresh: true)

      true
    end
  end

  scope :monthly, -> { where(resolution: "monthly") }
  scope :needs_refresh, -> { where(needs_refresh: true) }
  scope :aggr_values_ready, -> { where(aggr_values_ready: true) }

  validates :resolution, inclusion: { in: %w(monthly) }
  validates :utc_from, :utc_to, presence: true

  def refresh_monthly
    new_aggregates = {
      total_no_of_packages: 0,
      total_no_of_shipments: 0,
      total_weight: BigDecimal("0.0"),
      total_cost: {},
      total_revenue: {},
    }

    filtered_shipments.each do |shipment|
      new_aggregates[:total_no_of_packages] += shipment.number_of_packages
      new_aggregates[:total_no_of_shipments] += 1

      # Round weight to the nearest 3 digits. This will give a resolution of grams.
      new_aggregates[:total_weight] += BigDecimal(shipment.package_dimensions.total_weight.to_s).round(3)

      price = shipment.advanced_prices.select { |advanced_price| advanced_price.seller_id == company_id }.first

      if price && price.total_cost_price_amount > 0
        new_aggregates[:total_cost][price.cost_price_currency] ||= 0

        # Store monetary amounts in one-hundredths (e.g. cents and ører)
        new_aggregates[:total_cost][price.cost_price_currency] += (price.total_cost_price_amount * 100).round
      end

      if price && price.total_sales_price_amount > 0
        new_aggregates[:total_revenue][price.sales_price_currency] ||= 0

        # Store monetary amounts in one-hundredths (e.g. cents and ører)
        new_aggregates[:total_revenue][price.sales_price_currency] += (price.total_sales_price_amount * 100).round
      end
    end

    assign_attributes(new_aggregates)
    self.aggr_values_ready = true
    self.needs_refresh = false

    save!
  end

  def cascade_customer_statistics!
    cascade_monthly_customer_statistics!
  end

  def cascade_company_customer_statistics!
    cascade_monthly_company_customer_statistics!
  end

  def filtered_shipments
    if utc_from? && utc_to?
      shipments =
        Shipment
        .find_company_shipments(company_id: company_id)
        .where("shipments.created_at >= :from AND shipments.created_at <= :to", from: utc_from.beginning_of_day, to: utc_to.end_of_day)
        .where.not(state: [Shipment::States::CANCELLED, Shipment::States::REQUEST])
        .includes(:advanced_prices => [:advanced_price_line_items], :carrier_product => [:carrier])

      if customer_id
        shipments = shipments.where(customer_id: customer_id)
      elsif company_customer_id
        shipments = shipments.find_shipments_sold_to_company(company_id: company_id, customer_company_id: company_customer_id)
      end

      shipments = shipments.where(carrier_product_id: carrier_product_id) if carrier_product_id
      shipments = shipments.where(carrier_products: { carrier_id: carrier_id }) if carrier_id

      shipments
    else
      Shipment.none
    end
  end

  def total_cost_as_array
    (total_cost || {}).map do |currency, value|
      Money.new(currency: currency, value: BigDecimal(value.to_f / 100, Float::DIG))
    end
  end

  def total_revenue_as_array
    (total_revenue || {}).map do |currency, value|
      Money.new(currency: currency, value: BigDecimal(value.to_f / 100, Float::DIG))
    end
  end

  private

  # This methods makes sure to create monthly customer statistics entries for different combinations concerning the
  # current `AggregateShipmentStatistic` record.
  def cascade_monthly_customer_statistics!
    base_stats = self.class.monthly.where(company_id: company_id, company_customer_id: nil, utc_from: utc_from, utc_to: utc_to)

    # +customer, +carrier, -carrier_product
    base_stats.where(customer_id: customer_id, carrier_id: carrier_id, carrier_type: carrier_type, carrier_product_id: nil, carrier_product_type: nil).tap do |stats|
      if stats.empty?
        stats.create!(needs_refresh: true)
      else
        stats.update_all(needs_refresh: true)
      end
    end

    # +customer, -carrier, -carrier_product
    base_stats.where(customer_id: customer_id, carrier_id: nil, carrier_type: nil, carrier_product_id: nil, carrier_product_type: nil).tap do |stats|
      if stats.empty?
        stats.create!(needs_refresh: true)
      else
        stats.update_all(needs_refresh: true)
      end
    end

    # -customer, +carrier, -carrier_product
    base_stats.where(customer_id: nil, carrier_id: carrier_id, carrier_type: carrier_type, carrier_product_id: nil, carrier_product_type: nil).tap do |stats|
      if stats.empty?
        stats.create!(needs_refresh: true)
      else
        stats.update_all(needs_refresh: true)
      end
    end

    # -customer, -carrier, +carrier_product
    base_stats.where(customer_id: nil, carrier_id: nil, carrier_type: nil, carrier_product_id: carrier_product_id, carrier_product_type: carrier_product_type).tap do |stats|
      if stats.empty?
        stats.create!(needs_refresh: true)
      else
        stats.update_all(needs_refresh: true)
      end
    end

    # -customer, -carrier, -carrier_product
    base_stats.where(customer_id: nil, carrier_id: nil, carrier_type: nil, carrier_product_id: nil, carrier_product_type: nil).tap do |stats|
      if stats.empty?
        stats.create!(needs_refresh: true)
      else
        stats.update_all(needs_refresh: true)
      end
    end
  end

  # This methods makes sure to create monthly company customer statistics entries for different combinations concerning the
  # current `AggregateShipmentStatistic` record.
  def cascade_monthly_company_customer_statistics!
    base_stats = self.class.monthly.where(company_id: company_id, customer_id: nil, utc_from: utc_from, utc_to: utc_to)

    # +company_customer, +carrier, -carrier_product
    base_stats.where(company_customer_id: company_customer_id, carrier_id: carrier_id, carrier_type: carrier_type, carrier_product_id: nil, carrier_product_type: nil).tap do |stats|
      if stats.empty?
        stats.create!(needs_refresh: true)
      else
        stats.update_all(needs_refresh: true)
      end
    end

    # +company_customer, -carrier, -carrier_product
    base_stats.where(company_customer_id: company_customer_id, carrier_id: nil, carrier_type: nil, carrier_product_id: nil, carrier_product_type: nil).tap do |stats|
      if stats.empty?
        stats.create!(needs_refresh: true)
      else
        stats.update_all(needs_refresh: true)
      end
    end

    # -company_customer, +carrier, -carrier_product
    base_stats.where(company_customer_id: nil, carrier_id: carrier_id, carrier_type: carrier_type, carrier_product_id: nil, carrier_product_type: nil).tap do |stats|
      if stats.empty?
        stats.create!(needs_refresh: true)
      else
        stats.update_all(needs_refresh: true)
      end
    end

    # -company_customer, -carrier, +carrier_product
    base_stats.where(company_customer_id: nil, carrier_id: nil, carrier_type: nil, carrier_product_id: carrier_product_id, carrier_product_type: carrier_product_type).tap do |stats|
      if stats.empty?
        stats.create!(needs_refresh: true)
      else
        stats.update_all(needs_refresh: true)
      end
    end

    # -company_customer, -carrier, -carrier_product
    base_stats.where(company_customer_id: nil, carrier_id: nil, carrier_type: nil, carrier_product_id: nil, carrier_product_type: nil).tap do |stats|
      if stats.empty?
        stats.create!(needs_refresh: true)
      else
        stats.update_all(needs_refresh: true)
      end
    end
  end

  class Money
    attr_accessor :currency
    attr_accessor :value

    def initialize(currency:, value: 0.0)
      self.currency = currency
      self.value = value
    end
  end
end

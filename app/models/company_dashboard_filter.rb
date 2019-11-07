class CompanyDashboardFilter
  include ActiveModel::Validations

  attr_accessor :current_company
  attr_accessor :customer_id, :company_customer_id
  attr_accessor :carrier_id, :carrier_product_id

  validates! :current_company, presence: true

  def initialize(params = {})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def period_from=(value)
    @period_from =
      if value.present? && value.is_a?(String)
        begin
          Date.parse(value)
        rescue ArgumentError
          nil
        end
      else
        value
      end
  end
  attr_reader :period_from
  alias_method :custom_period_from=, :period_from=

  def period_to=(value)
    @period_to =
      if value.present? && value.is_a?(String)
        begin
          Date.parse(value)
        rescue ArgumentError
          nil
        end
      else
        value
      end
  end
  attr_reader :period_to
  alias_method :custom_period_to=, :period_to=

  attr_reader :predefined_period
  def predefined_period=(value)
    case value
    when "all_time"
      self.period_to = Date.today
      self.period_from = nil
    when "last_quarter"
      self.period_from = Date.today.at_beginning_of_quarter.last_quarter
      self.period_to = (period_from + 2.months).end_of_month
    when "last_six_months"
      self.period_to = Date.today
      self.period_from = period_to - 6.months
    when "last_year"
      self.period_to = Date.today
      self.period_from = period_to - 1.year
    when "last_two_years"
      self.period_to = Date.today
      self.period_from = period_to - 2.years
    end

    @predefined_period = value
  end

  def fetch_stats!
    raise "Be sure to check if filter is valid before invoking this method" if invalid?

    relation = aggregate_shipment_statistics
    earliest_date = (period_from.presence || relation.sort_by(&:utc_from).first.try(:utc_from) || 5.years.ago.to_date).beginning_of_month
    latest_date = period_to.presence || Date.today

    monthly_stats = {}
    month_format = "%Y-%m"

    current_date = earliest_date
    while current_date <= latest_date do
      monthly_stats[current_date.strftime(month_format)] = StatResult.new(date: current_date)
      current_date = current_date.advance(months: 1)
    end

    # Keep track of currencies across revenue and cost
    used_currencies = Set.new()

    relation.each do |stat|
      stat_result = StatResult.new_from_aggregated_stat(stat)

      stat_result.total_cost.each do |cost|
        used_currencies << cost.currency
      end

      stat_result.total_revenue.each do |revenue|
        used_currencies << revenue.currency
      end

      monthly_stats[stat.utc_from.strftime(month_format)] = stat_result
    end

    # Fill in revenue and cost for missing currencies
    monthly_stats.each do |_, stat_result|
      cost_currencies = stat_result.total_cost.map(&:currency)
      (used_currencies.to_a - cost_currencies).each do |currency|
        stat_result.total_cost << AggregateShipmentStatistic::Money.new(currency: currency)
      end

      revenue_currencies = stat_result.total_revenue.map(&:currency)
      (used_currencies.to_a - revenue_currencies).each do |currency|
        stat_result.total_revenue << AggregateShipmentStatistic::Money.new(currency: currency)
      end
    end

    @monthly_stats = monthly_stats.values

    self
  end

  # This method can be used in development where there isn't necessarily a lot of data to test the with.
  def fetch_dummy_stats!
    raise "Be sure to check if filter is valid before invoking this method" if invalid?

    latest_date = period_to.presence || Date.today

    monthly_stats = {}
    month_format = "%Y-%m"

    current_date = period_from.presence || 5.years.ago.to_date
    while current_date <= latest_date do
      stat_result = StatResult.new(date: current_date)
      monthly_stats[current_date.strftime(month_format)] = stat_result

      stat_result.total_no_of_shipments = rand(0..1000)
      stat_result.total_no_of_packages = rand(0..10000)
      stat_result.total_weight = BigDecimal(rand(0..200000), Float::DIG)
      stat_result.total_cost = [
        AggregateShipmentStatistic::Money.new(currency: "DKK", value: BigDecimal(rand(0..50000), Float::DIG)),
        AggregateShipmentStatistic::Money.new(currency: "USD", value: BigDecimal(rand(0..5000), Float::DIG)),
      ]
      stat_result.total_revenue = [
        AggregateShipmentStatistic::Money.new(currency: "DKK", value: BigDecimal(rand(0..100000), Float::DIG)),
        AggregateShipmentStatistic::Money.new(currency: "USD", value: BigDecimal(rand(0..1000), Float::DIG)),
        AggregateShipmentStatistic::Money.new(currency: "EUR", value: BigDecimal(rand(0..3000), Float::DIG)),
      ]

      current_date = current_date.advance(months: 1)
    end

    @monthly_stats = monthly_stats.values

    self
  end

  def total_no_of_shipments
    monthly_stats.sum(&:total_no_of_shipments)
  end

  def shipment_points
    monthly_stats.map do |s|
      Point.new(s.date, s.total_no_of_shipments)
    end
  end

  def total_no_of_packages
    monthly_stats.sum(&:total_no_of_packages)
  end

  def package_points
    monthly_stats.map do |s|
      Point.new(s.date, s.total_no_of_packages)
    end
  end

  def total_weight
    monthly_stats.sum(&:total_weight)
  end

  def weight_points
    monthly_stats.map do |s|
      Point.new(s.date, s.total_weight)
    end
  end

  def total_cost
    monthly_stats.reduce({}) do |memo, obj|
      obj.total_cost.each do |cost|
        memo[cost.currency] ||= MoneyWithPoints.new(currency: cost.currency)
        memo[cost.currency].value += cost.value
        memo[cost.currency].points << Point.new(obj.date, cost.value)
      end

      memo
    end.values
  end

  def sorted_total_cost
    total_cost.sort { |a, b| b.value <=> a.value }
  end

  def total_revenue
    monthly_stats.reduce({}) do |memo, obj|
      obj.total_revenue.each do |revenue|
        memo[revenue.currency] ||= MoneyWithPoints.new(currency: revenue.currency)
        memo[revenue.currency].value += revenue.value
        memo[revenue.currency].points << Point.new(obj.date, revenue.value)
      end

      memo
    end.values
  end

  def sorted_total_revenue
    total_revenue.sort { |a, b| b.value <=> a.value }
  end

  private

  attr_reader :monthly_stats

  def aggregate_shipment_statistics
    relation =
      AggregateShipmentStatistic
      .monthly
      .aggr_values_ready
      .where(company_id: current_company.id)
      .where(carrier_id: carrier_id.presence)
      .where(carrier_product_id: carrier_product_id.presence)
      .where(customer_id: customer_id.presence)
      .where(company_customer_id: company_customer_id.presence)

    relation = relation.where("utc_from >= ?", period_from.beginning_of_month) if period_from.present?
    relation = relation.where("utc_from <= ?", period_to.end_of_month) if period_to.present?

    relation
  end

  class StatResult
    attr_accessor :date
    attr_accessor :total_no_of_shipments
    attr_accessor :total_no_of_packages
    attr_accessor :total_weight
    attr_accessor :total_cost
    attr_accessor :total_revenue

    def self.new_from_aggregated_stat(stat)
      r = new(date: stat.utc_from)
      r.total_no_of_shipments = stat.total_no_of_shipments
      r.total_no_of_packages = stat.total_no_of_packages
      r.total_weight = stat.total_weight
      r.total_cost = stat.total_cost_as_array
      r.total_revenue = stat.total_revenue_as_array
      r
    end

    def initialize(date:)
      self.date = date
      self.total_no_of_shipments = 0
      self.total_no_of_packages = 0
      self.total_weight = 0
      self.total_cost = []
      self.total_revenue = []
    end
  end

  class MoneyWithPoints
    attr_accessor :currency, :value, :points

    def initialize(currency:, value: BigDecimal("0.0"))
      self.currency = currency
      self.value = value
      self.points = []
    end
  end

  Point = Struct.new(:timestamp, :value)

  private_constant :StatResult, :Point, :MoneyWithPoints
end

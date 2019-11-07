class CarrierProductRule < ActiveRecord::Base
  belongs_to :carrier_product, required: true

  has_one :shipment_weight_interval, foreign_key: "rule_id"
  has_one :number_of_packages_interval, foreign_key: "rule_id"

  after_initialize do |r|
    r.build_shipment_weight_interval(to_inclusive: true) unless r.shipment_weight_interval
    r.build_number_of_packages_interval(to_inclusive: true) unless r.number_of_packages_interval

    true
  end

  RULE_INTERVAL_DELEGATE_METHODS = [
    :enabled,
    :enabled?,
    :from,
    :from_inclusive,
    :to,
    :to_inclusive,

    :enabled=,
    :from=,
    :from_inclusive=,
    :to=,
    :to_inclusive=,
  ]

  delegate *RULE_INTERVAL_DELEGATE_METHODS, to: :shipment_weight_interval, prefix: true
  delegate *RULE_INTERVAL_DELEGATE_METHODS, to: :number_of_packages_interval, prefix: true

  def recipient_match_enabled
    recipient_type == "enabled"
  end

  alias_method :recipient_match_enabled?, :recipient_match_enabled

  def recipient_match_enabled=(value)
    self.recipient_type =
      if ["1", "true", true].include?(value)
        "enabled"
      end
  end

  def recipient_location_value
    recipient_location["value"] if recipient_location
  end

  def recipient_location_value=(value)
    self.recipient_location ||= {}
    recipient_location["value"] = value
  end

  def recipient_location_options
    [
      ["Within EU", "within_eu"],
      ["Outside EU", "outside_eu"],
    ]
  end

  def any_filters_enabled?
    shipment_weight_interval.try(:enabled?) ||
      number_of_packages_interval.try(:enabled?) ||
      recipient_match_enabled?
  end

  def match?(shipment_weight:, number_of_packages:, recipient_country_code:)
    if shipment_weight_interval.try(:enabled?)
      return false unless shipment_weight_interval.include?(shipment_weight)
    end

    if number_of_packages_interval.try(:enabled?)
      return false unless number_of_packages_interval.include?(number_of_packages)
    end

    if recipient_match_enabled?
      return false unless recipient_location_includes?(country_code: recipient_country_code)
    end

    true
  end

  def recipient_location_includes?(country_code:)
    if country_code.present?
      country = Country.find_country_by_alpha2(country_code)

      return false if country.nil?

      case recipient_location_value
      when "within_eu"
        country.in_eu?
      when "outside_eu"
        !country.in_eu?
      end
    end
  end

  class ShipmentWeightInterval < RuleInterval
    def include?(value)
      if from?
        from_value = BigDecimal(convert_string_to_value(from))
        mismatch = from_inclusive? ? (value < from_value) : (value <= from_value)

        return false if mismatch
      end

      if to?
        to_value = BigDecimal(convert_string_to_value(to))
        mismatch = to_inclusive? ? (value > to_value) : (value >= to_value)

        return false if mismatch
      end

      true
    end

    def convert_string_to_value(string)
      BigDecimal(string.to_s.gsub(",", "."))
    end
  end

  class NumberOfPackagesInterval < RuleInterval
    def include?(value)
      if from?
        from_value = Integer(from)
        mismatch = from_inclusive? ? (value < from_value) : (value <= from_value)

        return false if mismatch
      end

      if to?
        to_value = Integer(to)
        mismatch = to_inclusive? ? (value > to_value) : (value >= to_value)

        return false if mismatch
      end

      true
    end
  end
end

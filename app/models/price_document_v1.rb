class PriceDocumentV1

  SHIPMENT_CHARGE    = 'shipment_charge'
  DGR_CHARGE         = 'dgr_charge'
  PRICE_WEIGHT_RANGE = 'price_weight_range'
  PRICE_SINGLE       = 'price_single'

  module States
    OK       = 'ok'
    WARNINGS = 'warnings'
    FAILED   = 'failed'
  end

  module CalculationBases
    PACKAGE  = 'package'
    SHIPMENT = 'shipment'
    PALLET   = 'pallet'
    DISTANCE = 'distance'
  end

  # Parsing errors denoted by description, severity, consequence
  class ParseError
    module Severity
      WARNING = 'warning'
      FATAL   = 'fatal'
    end

    attr_reader :description, :severity, :consequence, :indices

    def initialize(description: nil, severity: nil, indices: nil, consequence: nil)
      @description = description
      @severity    = severity
      @indices     = indices
      @consequence = consequence
    end

  end

  # A single charge identified by name, type, calculation method
  class Charge
    attr_accessor :identifier, :name, :type

    def initialize(identifier: nil, name: nil, type: nil)
      @identifier = identifier
      @name       = name
      @type       = type
    end

  end

  # A formatted charge representation, can represent a group of charges
  class FormattedCharge < Charge
    attr_accessor :name, :total, :times, :parameters

    def initialize(name: nil, total: nil, times: 1, parameters: nil)
      super(name: name)
      @total      = total
      @times      = times
      @parameters = parameters
    end

  end

  # A single charge that is always the same amount regardless of weight
  class FlatCharge < Charge
    attr_accessor :amount

    def initialize(identifier: nil, name: nil, type: nil, amount: nil, times: nil)
      super(identifier: identifier, name: name, type: type)
      @amount = amount
    end

    def calculate(weight: nil, base: nil, package_dimensions: nil, import: nil)
      amount
    end
  end

  # Not sure
  class FlatWeightCharge < FlatCharge
    attr_reader :weight

    def initialize(identifier: nil, name: nil, type: nil, weight: nil, amount: nil)
      super(identifier: identifier, name: name, type: type, amount: amount)
      @weight = weight
    end

  end

  class FlatDistanceCharge < FlatCharge
    attr_reader :distance

    def initialize(identifier: nil, name: nil, type: nil, distance: nil, amount: nil)
      super(identifier: identifier, name: name, type: type, amount: amount)
      @distance = distance
    end

  end

  # Relative charge that is calculated as a percentage of a base price
  class RelativeCharge < Charge
    attr_reader :percentage

    def initialize(identifier: nil, name: nil, type: nil, percentage: nil)
      super(identifier: identifier, name: name, type: type)
      @percentage = percentage
    end

    def calculate(weight: nil, base: nil, package_dimensions: nil, import: nil)
      price = (base * percentage).fdiv 100
    end

  end

  # A charge that always lies between a low and high price range and is calculated based on weight
  #
  # The weight is multiplied by the price per interval
  class RangeCharge < Charge
    attr_reader :price_low, :price_high, :interval, :price_per_interval

    def initialize(identifier: nil, name: nil, type: nil, price_low: nil, price_high: nil, interval: nil, price_per_interval: nil)
      super(identifier: identifier, name: name, type: type)
      @price_low          = price_low
      @price_high         = price_high
      @interval           = interval
      @price_per_interval = price_per_interval
    end

    def calculate(weight: nil, base: nil, package_dimensions: nil, import: nil)
      value = (weight / interval) * price_per_interval
      if value < price_low
        price = price_low
      elsif value > price_high
        price = price_high
      else
        price = value
      end
      price
    end
  end

  # A charge that is calculated based on weight, and only applies when the weight lies between the low and high weight range
  #
  # SHOULD PROBABLY RETURN NIL IF CHARGE IS NOT APPLIED? IE OUTSIDE WEIGHT RANGE
  # DOESNT NEED PRICE HIGH? DOESNT LOOK LIKE ITS USED
  class WeightRangeCharge < Charge
    attr_reader :weight_low, :weight_high, :price_low, :interval, :price_per_interval

    def initialize(identifier: nil, name: nil, type: nil, weight_low: nil, weight_high: nil, price_low: nil, interval: nil, price_per_interval: nil)
      super(identifier: identifier, name: name, type: type)
      @weight_low         = weight_low
      @weight_high        = weight_high
      @price_low          = price_low
      @interval           = interval
      @price_per_interval = price_per_interval
    end

    def matches?(weight: nil)
      weight >= weight_low && weight <= weight_high
    end

    # returns an array of all the weights in the range
    #
    # @return [Array<Int>]
    def to_a
      weights = [weight_low]
      i = weight_low

      while i < weight_high
        weights << i + interval
        i += interval
      end
      weights << weight_high
      weights.uniq
    end

    def calculate(weight: nil, base: nil, package_dimensions: nil, import: nil)
      base_price         = price_low
      steps              = weight - weight_low
      price              = (steps / interval) * price_per_interval

      full_price = (base_price + price)
    end

  end

  # A charge that is applied based on some algorithm or logic
  #
  # Should be subclassed with subclass specifying algorithm
  class LogicalCharge < FlatCharge
    attr_accessor :threshold, :amount

    def initialize(identifier: nil, name: nil, type: nil, threshold: nil, amount: nil)
      super(identifier: identifier, name: name, type: type, amount: amount)
      @threshold = threshold
    end

    def times(current_amount: nil)
      (current_amount.to_f / amount.to_f)
    end

  end

  # Represents a zone with a name, a list of countries
  class Zone
    attr_accessor :name, :countries

    class Country
      attr_accessor :country_code, :zip_codes

      def initialize(country_code: nil, zip_codes: [])
        @country_code = country_code
        @zip_codes    = zip_codes
      end

      def matches?(country_code: nil, zip_code: nil)
        zip_code_match     = self.zip_codes.any?{ |zc| zc.matches?(zip_code: zip_code) }
        country_code_match = self.country_code.downcase == country_code.downcase

        zip_code_match && country_code_match
      end

      def zip_codes_specified?
        !self.zip_codes.empty?
      end

    end

    class ZipCode
      attr_accessor :zip_code

      def initialize(zip_code: nil)
        @zip_code     = zip_code
      end

      def matches?(zip_code: nil)
        self.zip_code == zip_code
      end

      def to_s
        "#{zip_code}"
      end

    end

    class ZipCodeRange
      attr_accessor :zip_low, :zip_high

      def initialize(zip_low: nil, zip_high: nil)
        @zip_low      = zip_low
        @zip_high     = zip_high
      end

      def matches?(zip_code: nil)
        zip_code.to_i >= zip_low.to_i && zip_code.to_i <= zip_high.to_i
      end

      def to_s
        "#{zip_low}-#{zip_high}"
      end
    end

    def initialize(name: nil, countries: [])
      @name      = name
      @countries = countries
    end

    def has_zip_code?(country_code: nil, zip_code: nil)
      self.countries.any?{ |country| country.matches?(country_code: country_code, zip_code: zip_code.to_s) }
    end

    def has_country_code?(country_code: nil)
      self.countries.any?{ |country| country.country_code.downcase == country_code.downcase }
    end

    # def to_s
    #   "name: #{@name}, country_codes: #{@country_codes.join(', ')}, zip_codes: #{@zip_codes.join(', ')}"
    # end
  end

  # Contains all the information needed to calculate shipment pricing for a single zone
  #
  # Has an associated zone and a list of charges to be applied in that zone
  class ZonePrice
    attr_reader :zone, :charges

    # @param zone [Zone]
    # @param charges [Array<Charge>]
    def initialize(zone: nil, charges: [])
      @zone    = zone
      @charges = charges
    end

  end

  # A collection of all price calculations for a shipment
  class PriceCalculations
    attr_reader :price_calculations

    def initialize(price_calculations: [])
      @price_calculations = price_calculations
    end

    def charges
      charges  = price_calculations.sum{ |calculation| calculation.formatted_charges }
      return charges
    end

    def total
      price_calculations.sum{ |calculation| calculation.total }
    end

    def empty?
      price_calculations.empty?
    end

  end

  # A single price calculation for either a package or a shipment
  class PriceCalculation
    attr_reader :base_charge, :surcharges, :applied_metric, :package_dimensions, :zone, :import, :basis

    # @param base_charge [FlatCharge/WeightRangeCharge]
    # @param surcharges [Array<Charge>]
    def initialize(base_charge: nil, surcharges: [], applied_metric: nil, package_dimensions: nil, zone: nil, import: nil, basis: nil)
      @base_charge        = base_charge
      @surcharges         = surcharges
      @applied_metric     = applied_metric
      @package_dimensions = package_dimensions
      @zone               = zone
      @import             = import
      @basis              = basis
    end

    def total
      base   = base_charge.calculate(weight: applied_metric)
      result = base + surcharges.sum { |charge| charge.calculate(weight: applied_metric, base: base, package_dimensions: package_dimensions) }

      return result
    end

    def formatted_charges
      base    = base_charge.calculate(weight: applied_metric)
      charges = []

      parameter = Hash.new
      case basis
        when CalculationBases::PALLET
          parameter[:pallets] = package_dimensions.number_of_packages
        when CalculationBases::DISTANCE
          parameter[:distance] = applied_metric
        else
          parameter[:weight] = applied_metric
      end

      charges << FormattedCharge.new(name: base_charge.name, total: base, parameters: parameter)

      surcharges.each do |surcharge|
        charge = FormattedCharge.new(name: surcharge.name, total: surcharge.calculate(weight: applied_metric, base: base, package_dimensions: package_dimensions, import: import))
        charge.times = surcharge.times(current_amount: charge.total) if surcharge.kind_of?(LogicalCharge)
        charge.parameters = {base: base, percentage: surcharge.percentage} if surcharge.kind_of?(RelativeCharge)
        charge.parameters = {low: surcharge.price_low, high: surcharge.price_high, per: surcharge.price_per_interval, weight: applied_metric} if surcharge.kind_of?(RangeCharge)
        charge.parameters = {threshold: surcharge.threshold, amount: surcharge.amount} if surcharge.kind_of?(LogicalCharge)

        # Round each parameter
        charge.parameters.map{ |key, value| charge.parameters[key] = value } if charge.parameters.present?

        charges << charge
      end

      # Only select applicable charges
      charges.select! { |charge| charge.total > 0 }

      return charges
    end

    def to_s
      string = ""
      formatted_charges.each do |charge|
        string += "#{charge.name}: #{charge.total}\n"
      end
      string += "total: #{total.to_f}"

      return string
    end

  end

  # INSTANCE METHODS FOR PRICE DOCUMENT

  attr_reader :state, :calculation_basis, :currency, :zones, :zone_prices, :parsing_errors

  def initialize(state: nil, calculation_basis: nil, currency: nil, zones: nil, zone_prices: nil, parsing_errors: nil)
    @state             = state
    @calculation_basis = calculation_basis
    @currency          = currency
    @zones             = zones
    @zone_prices       = zone_prices
    @parsing_errors    = parsing_errors
  end

  def max_weight(zone: nil)
    zone_price = zone_price_from_zone(zone: zone)

    weight_charge_ranges = filter_charges_by_type(charges: zone_price.charges, type: PRICE_WEIGHT_RANGE)
    weight_range_max     = weight_charge_ranges.map { |wrc| wrc.weight_high }.sort! { |w1, w2| w2 <=> w1 }.first
    weight_charges       = filter_charges_by_type(charges: zone_prices.first.charges, type: PRICE_SINGLE)
    weight_charge_max    = weight_charges.map! { |wc| wc.weight }.sort! { |w1, w2| w2 <=> w1 }.first

    if weight_charge_max.nil?
      return weight_range_max
    elsif weight_range_max.nil?
      return weight_charge_max
    end

    [weight_range_max, weight_charge_max].max
  rescue
    return false
  end

  def out_of_range?(value: nil, zone: nil)

    value > max_weight(zone: zone)
  rescue
    return true
  end

  def zone_price_from_zone(zone: nil)
    zone_prices.select{ |zp| zp.zone.name == zone.name }.first
  end

  def zone_from_country_code(country_code: nil)
    zone = zones.select { |z| z.country_codes.include?(country_code.downcase) }.first
    zone ? zone : false
  end

  def zone_from_zip_code(country_code: nil, zip_code: nil)
    zone = zones.select{ |zone| zone.has_zip_code?(country_code: country_code, zip_code: zip_code) }.first
    zone ? zone : false
  end

  def default_zone_from_country_code(country_code: nil)
    zone = self.zones.select { |zone| zone.countries.any?{ |country| country.country_code.downcase == country_code.downcase && !country.zip_codes_specified? } }.first
    zone ? zone : false
  end

  def zone_from_country_and_zip_code(country_code: nil, zip_code: nil)
    zone = zone_from_zip_code(country_code: country_code, zip_code: zip_code) if zip_code
    zone = default_zone_from_country_code(country_code: country_code) unless zone

    zone ? zone : false
  end

  # @param charges [Array<Charge>]
  def filter_charges_by_identifier(charges: nil, identifier: nil)
    filtered_charges = charges.select { |charge| charge.identifier == identifier }
  end

  # @param charges [Array<Charge>]
  def filter_charges_by_type(charges: nil, type: nil)
    filtered_charges = charges.select { |charge| charge.type == type }
  end

  # @param weight_ranges [Array<WeightRangeCharge>]
  def find_weight_range_matching_weight(weight_ranges: nil, weight: nil)
    weight_ranges.each do |range|
      return range if weight >= range.weight_low && weight <= range.weight_high
    end
    return false
  end

  # Calulates the base price for shipment
  #
  # @param basis [int] : either weight or number of pallets
  def calculate_base_weight_price(charges: nil, basis: nil)
    weight_charges       = filter_charges_by_identifier(charges: charges, identifier: SHIPMENT_CHARGE)
    weight_charges.map! do |charge|
      if charge.class == FlatWeightCharge
        [charge, (charge.weight - basis).abs]
      elsif charge.class == WeightRangeCharge
        [charge, (charge.weight_low - basis).abs]
      end
    end

    # only select weight charges greater than or equal to the specified weight
    weight_charges.select! do |charge, diff|
      if charge.class == FlatWeightCharge
        charge.weight >= basis
      elsif charge.class == WeightRangeCharge

        # if matching weight range is found, just use that
        if charge.matches?(weight: basis)
          differences = charge.to_a.map { |w| [w, (w - basis).abs] }
          differences.select!{ |w, diff| w >= basis}
          match = differences.sort { |a, b| a.last <=> b.last }.first.first

          return FlatWeightCharge.new(identifier: SHIPMENT_CHARGE, name: charge.name, amount: charge.calculate(weight: match), weight: match)
        end
        charge.weight_low >= basis
      end
    end

    weight_charges.sort! { |a, b| a.last <=> b.last }
    charge = weight_charges.first.try(:first).try(:clone)

    # weight rounds up to a weight range, so use lower weight bound for calculation
    if charge.class == WeightRangeCharge
      charge = FlatWeightCharge.new(identifier: SHIPMENT_CHARGE, name: charge.name, amount: charge.calculate(weight: charge.weight_low), weight: charge.weight_low)
    end

    charge.blank? ? false : charge
  end

  # Calculates the base price of a shipment based on distance
  #
  def calculate_base_distance_price(charges: nil, distance_in_kilometers: nil)
    distance_charge = filter_charges_by_identifier(charges: charges, identifier: SHIPMENT_CHARGE).first

    return nil if distance_charge.class != RangeCharge
    FlatDistanceCharge.new(identifier: SHIPMENT_CHARGE, name: distance_charge.name, amount: distance_charge.calculate(weight: distance_in_kilometers), distance: distance_in_kilometers)
  end

  # @param charges [Array<Charge>]
  def filter_surcharges(charges: nil, dangerous_goods: false)
    excluded_charge_identifiers = dangerous_goods ? [SHIPMENT_CHARGE] : [SHIPMENT_CHARGE, DGR_CHARGE]
    charges.reject { |charge| excluded_charge_identifiers.include?(charge.identifier) }
  end

  def package_based_price_calculation?
    self.calculation_basis == CalculationBases::PACKAGE
  end

  def pallet_based_price_calculation?
    self.calculation_basis == CalculationBases::PALLET
  end

  def distance_based_price_calculation?
    self.calculation_basis == CalculationBases::DISTANCE
  end

  # Check if there is a price specified for weight in given zone
  #
  # @return [Boolean]
  def value_eligible_for_calculation?(value: nil, zone: nil)
    inside_value_range = !self.out_of_range?(value: value, zone: zone)

    (value.present? && inside_value_range) ? true : false
  end

  # Returns one or more price calculations depending on price document's calculation basis
  #
  # @return [PriceCalculations]
  def calculate_price_for_shipment(sender_country_code: nil, sender_zip_code: nil, recipient_country_code: nil, recipient_zip_code: nil, package_dimensions: nil, margin: nil, import: nil, dangerous_goods: false, distance_in_kilometers: nil)
    # use sender location in price calculations for import shipments
    if import
      country_code = sender_country_code
      zip_code     = sender_zip_code
    else
      country_code = recipient_country_code
      zip_code     = recipient_zip_code
    end

    zone = zone_from_country_and_zip_code(country_code: country_code, zip_code: zip_code)
    return false unless zone

    zone_price  = zone_price_from_zone(zone: zone)
    return false unless zone_price

    if self.pallet_based_price_calculation?
      calculate_price_for_pallet_based_shipment(zone: zone, package_dimensions: package_dimensions, margin: margin, import: import, dangerous_goods: dangerous_goods)
    elsif self.distance_based_price_calculation?
      calculate_price_for_distance_based_shipment(zone: zone, package_dimensions: package_dimensions, margin: margin, import: import, dangerous_goods: dangerous_goods, distance_in_kilometers: distance_in_kilometers)
    else
      calculate_price_for_weight_based_shipment(zone: zone, package_dimensions: package_dimensions, margin: margin, import: import, dangerous_goods: dangerous_goods)
    end

  rescue => e
    return false
  end

  # Calculation based on weight
  #
  def calculate_price_for_weight_based_shipment(zone: nil, package_dimensions: nil, margin: nil, import: nil, dangerous_goods: false)
    zone_price  = zone_price_from_zone(zone: zone)
    calculations = []

    package_dimensions.dimensions.each do |dimensions|


      # Base either applied weight on individual package or shipment
      if self.package_based_price_calculation?
        applied_weight = package_dimensions.loading_meter? ? volume_weight : [dimensions.weight, dimensions.volume_weight].max
      else
        weight         = package_dimensions.total_weight
        volume_weight  = package_dimensions.total_volume_weight
        applied_weight = package_dimensions.loading_meter? ? volume_weight : [weight, volume_weight].max
      end


      weight_is_eligible = value_eligible_for_calculation?(value: applied_weight, zone: zone)
      return false unless weight_is_eligible

      base_charge        = calculate_base_weight_price(charges: zone_price.charges, basis: applied_weight)

      return unless base_charge
      base_charge.amount *= (margin / 100.0) + 1 if margin.present?
      return false if base_charge.nil?

      surcharges = filter_surcharges(charges: zone_price.charges, dangerous_goods: dangerous_goods)
      pallet = self.pallet_based_price_calculation?
      calculations << PriceCalculation.new(base_charge: base_charge, surcharges: surcharges, applied_metric: base_charge.weight, package_dimensions: package_dimensions, zone: zone, import: import)
      return PriceCalculations.new(price_calculations: calculations) unless self.package_based_price_calculation?
    end
    return PriceCalculations.new(price_calculations: calculations)
  end

  def calculate_price_for_pallet_based_shipment(zone: nil, package_dimensions: nil, margin: nil, import: nil, dangerous_goods: false)
    pallet_size_to_identifier = {
      [60,  40] => :quarter,
      [80,  60] => :half,
      [120, 80] => :whole,
    }

    pallet_identifier_to_number = {
      :quarter => 0.25,
      :half    => 0.50,
      :whole   => 1.00,
    }

    pallet_sizes = package_dimensions.dimensions.map do |dimension|
      length, width = Integer(dimension.length), Integer(dimension.width)
      pallet_size_to_identifier[[length, width]] || pallet_size_to_identifier[[width, length]] || :unknown
    end

    pallet_total = pallet_sizes.sum do |pallet_size|
      pallet_identifier_to_number[pallet_size] || pallet_identifier_to_number[:whole]
    end

    pallet_value =
      if pallet_total > 0.50
        pallet_total.ceil
      else
        pallet_total
      end

    return false unless value_eligible_for_calculation?(value: pallet_value, zone: zone)

    zone_price = zone_price_from_zone(zone: zone)
    base_charge = calculate_base_weight_price(charges: zone_price.charges, basis: pallet_value)
    return unless base_charge

    base_charge.amount *= pallet_value if pallet_value > 1
    base_charge.amount *= (margin / 100.0) + 1 if margin.present?

    surcharges = filter_surcharges(charges: zone_price.charges, dangerous_goods: dangerous_goods)

    PriceCalculations.new(price_calculations: [
      PriceCalculation.new(
        base_charge: base_charge,
        surcharges: surcharges,
        applied_metric: base_charge.weight,
        package_dimensions: package_dimensions,
        zone: zone,
        import: import,
        basis: CalculationBases::PALLET,
      )
    ])
  rescue => e
    ExceptionMonitoring.report!(e)
    nil
  end

  # Calculation based on distance (kilometers)
  #
  def calculate_price_for_distance_based_shipment(zone: nil, package_dimensions: nil, margin: nil, import: nil, dangerous_goods: false, distance_in_kilometers: nil)
    rounded_distance = distance_in_kilometers.try(:ceil)

    zone_price  = zone_price_from_zone(zone: zone)
    base_charge = calculate_base_distance_price(charges: zone_price.charges, distance_in_kilometers: rounded_distance)

    return false if base_charge.nil?
    base_charge.amount *= (margin / 100.0) + 1 if margin.present?
    surcharges = filter_surcharges(charges: zone_price.charges, dangerous_goods: dangerous_goods)


    basis = CalculationBases::DISTANCE
    calculations = [PriceCalculation.new(base_charge: base_charge, surcharges: surcharges, applied_metric: base_charge.distance, package_dimensions: package_dimensions, zone: zone, import: import, basis: basis)]
    return PriceCalculations.new(price_calculations: calculations)
  end


end

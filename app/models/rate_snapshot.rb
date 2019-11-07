module RateSnapshot
  class << self
    def build!(price_document:, margin_percentage:)
      body = BodyV2.new(price_document: price_document, margin_percentage: margin_percentage)
      body.build! # 💪
      body
    end

    def build_with_config!(price_document:, margin_config:)
      body = BodyWithConfig.new(price_document: price_document, margin_config: margin_config)
      body.build! # 💪
      body
    end
  end

  class BodyV2
    attr_reader :price_document
    attr_reader :margin_percentage

    def initialize(price_document:, margin_percentage:)
      @price_document = price_document
      @margin_percentage = margin_percentage
      @factor = margin_percentage.to_f/100.0 + 1.0
    end

    def build!
      @zone_grouping = {}
      @zone_pricing = {}

      price_document.zone_prices.each do |zone_price|
        structure = ZoneChargeStructure.new(zone_price_charges: zone_price.charges)

        if @zone_grouping.key?(structure)
          @zone_grouping[structure] << zone_price.zone
        else
          @zone_grouping[structure] = [zone_price.zone]
        end

        @zone_pricing[zone_price.zone.name] = zone_price.charges.map do |charge|
          ChargeCalculation.calculate_from_charge(charge, factor: factor)
        end
      end
    end

    def to_json_hash
      hash = {
        "version" => "v2",
        "currency" => price_document.currency,
      }

      hash["grouped_zones"] = @zone_grouping.map do |_, zones|
        zones.map do |zone|
          {
            "name" => zone.name,
            "regions" => zone.countries.map { |region|
              {
                "country_code" => region.country_code.upcase,
                "country_name" => Country.find_country_by_alpha2(region.country_code).try(:name),
              }
            }
          }
        end
      end

      hash["prices_per_zone_groups"] = @zone_grouping.map do |charge_structure, zones|
        {
          "zones" => zones.map { |zone|
            {
              "name" => zone.name
            }
          },
          "prices" => charge_structure.structure.each_with_index.map { |charge_data, index|
            {
              "charge_type" => charge_data["charge_type"],
              "charge_data" => charge_data,
              "zone_prices" => zones.map { |zone|
                @zone_pricing[zone.name][index]
              }
            }
          }
        }
      end

      hash
    end

    private

    attr_reader :factor
  end

  class BodyWithConfig
    attr_reader :price_document
    attr_reader :margin_config

    def initialize(price_document:, margin_config:)
      @price_document = price_document
      @margin_config = margin_config
    end

    def build!
      @zone_grouping = {}
      @zone_pricing = {}

      price_document.zone_prices.each do |zone_price|
        structure = ZoneChargeStructure.new(zone_price_charges: zone_price.charges)
        zone_index = price_document.zones.index do |zone|
          zone_price.zone.name == zone.name
        end

        if @zone_grouping.key?(structure)
          @zone_grouping[structure] << zone_price.zone
        else
          @zone_grouping[structure] = [zone_price.zone]
        end

        @zone_pricing[zone_price.zone.name] = zone_price.charges.each_with_index.map do |charge, charge_index|
          row = margin_config.config_document["zones"][String(zone_index)].try(:[], charge_index)
          ChargeCalculationWithMarkUp.calculate_from_charge(charge, margin_amount_as_string: row.try(:[], "margin_amount"), interval_margin_amount_as_string: row.try(:[], "interval_margin_amount"))
        end
      end
    end

    def to_json_hash
      hash = {
        "version" => "v2",
        "currency" => price_document.currency,
      }

      hash["grouped_zones"] = @zone_grouping.map do |_, zones|
        zones.map do |zone|
          {
            "name" => zone.name,
            "regions" => zone.countries.map { |region|
              {
                "country_code" => region.country_code.upcase,
                "country_name" => Country.find_country_by_alpha2(region.country_code).try(:name),
              }
            }
          }
        end
      end

      hash["prices_per_zone_groups"] = @zone_grouping.map do |charge_structure, zones|
        {
          "zones" => zones.map { |zone|
            {
              "name" => zone.name
            }
          },
          "prices" => charge_structure.structure.each_with_index.map { |charge_data, index|
            {
              "charge_type" => charge_data["charge_type"],
              "charge_data" => charge_data,
              "zone_prices" => zones.map { |zone|
                @zone_pricing[zone.name][index]
              }
            }
          }
        }
      end

      hash
    end
  end

  class ZoneChargeStructure
    attr_reader :structure

    def initialize(zone_price_charges:)
      @structure = zone_price_charges.map { |charge| ChargeCharacteristics.detect_from_charge(charge) }.compact
    end

    def ==(other)
      self.structure == other.structure
    end

    alias eql? ==

    def hash
      structure.hash
    end
  end

  module ChargeClassification
    extend ActiveSupport::Concern

    class_methods do
      def charge_class_name(charge)
        charge.class.name.split("::").last
      end
    end

    def charge_class_name(*args)
      self.class.charge_class_name(*args)
    end
  end

  module ChargeCharacteristics
    include ChargeClassification

    class << self
      def detect_from_charge(charge)
        return nil if charge.identifier != "shipment_charge"

        charge_type = charge_class_name(charge)

        case charge_type
        when "FlatWeightCharge"
          {
            "charge_type" => charge_type,
            "weight" => charge.weight.to_f,
          }
        when "WeightRangeCharge"
          {
            "charge_type" => charge_type,
            "weight_low" => charge.weight_low.to_f,
            "weight_high" => charge.weight_high.to_f,
            "interval" => charge.interval.to_f,
          }
        when "RangeCharge"
          {
            "charge_type" => charge_type,
            "interval" => charge.interval.to_f,
          }
        else
          Rails.logger.error "TODO: #{charge_type} was not recognized"
          {}
        end
      end
    end
  end

  module ChargeCalculation
    include ChargeClassification

    class << self
      def calculate_from_charge(charge, factor:)
        charge_type = charge_class_name(charge)

        case charge_type
        when "FlatWeightCharge"
          {
            "charge_type" => charge_type,
            "amount" => ActiveSupport::NumberHelper.number_to_rounded((charge.amount * factor).to_f, precision: 2),
          }
        when "WeightRangeCharge"
          {
            "charge_type" => charge_type,
            "price_low" => ActiveSupport::NumberHelper.number_to_rounded((charge.price_low * factor).to_f, precision: 2),
            "price_per_interval" => ActiveSupport::NumberHelper.number_to_rounded((charge.price_per_interval * factor).to_f, precision: 2),
          }
        when "RangeCharge"
          {
            "charge_type" => charge_type,
            "price_low" => ActiveSupport::NumberHelper.number_to_rounded((charge.price_low * factor).to_f, precision: 2),
            "price_high" => ActiveSupport::NumberHelper.number_to_rounded((charge.price_high * factor).to_f, precision: 2),
            "price_per_interval" => ActiveSupport::NumberHelper.number_to_rounded((charge.price_per_interval * factor).to_f, precision: 2),
          }
        else
          Rails.logger.error "TODO: #{charge_type} was not recognized"
          {}
        end
      end
    end
  end

  module ChargeCalculationWithMarkUp
    include ChargeClassification

    class << self
      def calculate_from_charge(charge, margin_amount_as_string:, interval_margin_amount_as_string:)
        mark_up = margin_amount_as_string.present? ? BigDecimal(margin_amount_as_string) : nil
        interval_mark_up = interval_margin_amount_as_string.present? ? BigDecimal(interval_margin_amount_as_string) : nil
        charge_type = charge_class_name(charge)

        case charge_type
        when "FlatWeightCharge"
          {
            "charge_type" => charge_type,
            "amount" => mark_up ? ActiveSupport::NumberHelper.number_to_rounded((charge.amount + mark_up).to_f, precision: 2) : nil,
          }
        when "WeightRangeCharge"
          {
            "charge_type" => charge_type,
            "price_low" => mark_up ? ActiveSupport::NumberHelper.number_to_rounded((charge.price_low + mark_up).to_f, precision: 2) : nil,
            "price_per_interval" => interval_mark_up ? ActiveSupport::NumberHelper.number_to_rounded((charge.price_per_interval + interval_mark_up).to_f, precision: 2) : nil,
          }
        when "RangeCharge"
          {
            "charge_type" => charge_type,
            "price_low" => mark_up ? ActiveSupport::NumberHelper.number_to_rounded((charge.price_low + mark_up).to_f, precision: 2) : nil,
            "price_high" => mark_up ? ActiveSupport::NumberHelper.number_to_rounded((charge.price_high + mark_up).to_f, precision: 2) : nil,
            "price_per_interval" => nil,
          }
        else
          Rails.logger.error "TODO: #{charge_type} was not recognized"
          {}
        end
      end
    end
  end
end

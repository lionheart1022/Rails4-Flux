class Surcharge < ActiveRecord::Base
  AVAILABLE_CALCULATION_METHODS = %w(price_percentage price_fixed)
  CALCULATION_METHOD_OPTIONS = [["%", "price_percentage"], ["+", "price_fixed"]]

  validates :calculation_method, presence: true, inclusion: { in: AVAILABLE_CALCULATION_METHODS }
  validates :description, presence: true

  class << self
    def calculation_method_options
      CALCULATION_METHOD_OPTIONS
    end

    def build_surcharge_by_predefined_type(predefined_type)
      CarrierConfig.config.each do |_, carrier_props|
        carrier_props.fetch(:surcharges).each do |surcharge_predefined_type, surcharge_props|
          if surcharge_predefined_type == predefined_type
            surcharge_klass = surcharge_props.fetch(:klass).constantize
            surcharge_attrs = surcharge_props.slice(:description, :calculation_method)
            return surcharge_klass.new(surcharge_attrs)
          end
        end
      end

      # Fall back to a regular surcharge
      Surcharge.new
    end
  end

  def charge_value
    charge_data["value"] if charge_data
  end

  def charge_value_as_numeric
    if charge_value
      BigDecimal(charge_value.sub(",", "."))
    end
  end

  def charge_value=(value)
    self.charge_data ||= {}
    self.charge_data["value"] = value
  end

  def calculation_method
    charge_data["calculation_method"] if charge_data
  end

  def calculation_method=(value)
    self.charge_data ||= {}
    self.charge_data["calculation_method"] = value
  end

  def formatted_value
    if charge_value
      case
      when price_percentage?
        "#{charge_value} %"
      when price_fixed?
        "+ #{charge_value}"
      end
    end
  end

  # Indicate in the UI that this surcharge will be applied when we receive updates.
  def carrier_feedback_surcharge?
    false
  end

  # Default surcharges are always applied.
  def default_surcharge?
    type.nil?
  end

  def calculated_method_locked_to
  end

  def price_percentage?
    calculation_method == "price_percentage"
  end

  def price_fixed?
    calculation_method == "price_fixed"
  end

  def similar?(other)
    self.attributes.except("id") == other.attributes.except("id")
  end
end

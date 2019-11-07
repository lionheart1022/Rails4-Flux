module CarrierProductForm
  def self.new_product_for_carrier(carrier)
    if carrier.type.nil?
      Custom.new
    else
      NonCustom.new
    end
  end

  def self.edit_product(carrier_product)
    if carrier_product.type.nil?
      Custom.new(record: carrier_product)
    else
      NonCustom.new(record: carrier_product)
    end
  end

  class Base
    include ActiveModel::Model

    attr_reader :record

    def assign_params(params)
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end

    def record_attributes
      raise "override in subclass"
    end
  end

  private_constant :Base

  class Custom < Base
    CUSTOM_LABEL_VARIANTS = %w(standard samskip new_default_107x190 new_default_107x165)
    CUSTOM_LABEL_DEFAULT = CUSTOM_LABEL_VARIANTS.first

    attr_accessor :name
    attr_accessor :track_trace_method
    attr_accessor :basis
    attr_accessor :volume_weight_type
    attr_accessor :custom_volume_weight_enabled
    attr_accessor :volume_weight_factor
    attr_accessor :custom_label
    attr_accessor :custom_label_variant
    attr_accessor :truck_driver
    attr_accessor :import

    validates :name, presence: true
    validates :volume_weight_factor, presence: true, if: :custom_volume_weight_enabled?
    validates :custom_label_variant, presence: true, inclusion: { in: CUSTOM_LABEL_VARIANTS }, if: :custom_label?

    def initialize(params = {})
      if @record = params.delete(:record)
        assign_params(
          name: record.name,
          track_trace_method: record.track_trace_method,
          basis: record.options.basis,
          volume_weight_type: record.options.volume_weight_type,
          custom_volume_weight_enabled: record.custom_volume_weight_enabled,
          volume_weight_factor: record.volume_weight_factor,
          custom_label: record.custom_label,
          custom_label_variant: record.custom_label_variant,
          truck_driver: record.truck_driver_enabled,
          import: record.import?,
        )
      else
        super
      end
    end

    def record_attributes
      {
        name: name,
        track_trace_method: track_trace_method,
        custom_label: custom_label,
        custom_label_variant: custom_label_variant,
        volume_weight_factor: volume_weight_factor,
        custom_volume_weight_enabled: custom_volume_weight_enabled,
        options: CarrierProductOptions.new(basis: basis, volume_weight_type: volume_weight_type),
        truck_driver_enabled: truck_driver,
        exchange_type_import: exchange_type_import_value,
      }
    end

    def exchange_type_import_value
      %w(1 true).include?(import.to_s)
    end

    def custom_volume_weight_enabled=(value)
      @custom_volume_weight_enabled = [1, "1", true, "true"].include?(value)
    end

    alias_method :custom_volume_weight_enabled?, :custom_volume_weight_enabled

    def custom_label_variant
      @custom_label_variant || CUSTOM_LABEL_DEFAULT
    end

    def custom_label=(value)
      @custom_label = [1, "1", true, "true"].include?(value)
    end

    alias_method :custom_label?, :custom_label

    def basis_options
      values = CarrierProductOptions.bases
      labels = values.map &:titleize

      labels.zip(values)
    end

    def volume_weight_type_options
      values = CarrierProductOptions.volume_weight_types
      labels = values.map &:titleize

      labels.zip(values)
    end

    def track_trace_method_options
      [
        ["trackload.com", CarrierProduct::TrackTraceMethods::TRACKLOAD],
        ["track-trace.com/container", CarrierProduct::TrackTraceMethods::TRACKTRACE_CONTAINER],
      ]
    end

    def form_partial_path
      "form_custom_product"
    end
  end

  class NonCustom < Base
    attr_accessor :transit_time

    def initialize(params = {})
      if @record = params.delete(:record)
        assign_params(
          transit_time: record.transit_time,
        )
      else
        super
      end
    end

    def record_attributes
      {
        transit_time: transit_time,
      }
    end

    def form_partial_path
      "form_non_custom_product"
    end
  end
end

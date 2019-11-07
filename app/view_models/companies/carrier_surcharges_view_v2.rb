class Companies::CarrierSurchargesViewV2
  attr_reader :current_company
  attr_reader :carrier

  def initialize(current_company:, carrier:)
    @current_company = current_company
    @carrier = carrier

    @carrier_products = CarrierProduct.where(company: @current_company, carrier: @carrier, is_disabled: false)
    @all_surcharges = @carrier.list_all_surcharges
    @enabled_surcharges = @carrier.enabled_surcharges
    @all_surcharges_on_products = SurchargeOnProduct.where(carrier_product_id: @carrier_products.map(&:id))

    @surcharges_with_expiration = SurchargeWithExpiration.where(owner_type: "SurchargeOnCarrier", owner_id: @all_surcharges.map(&:id))
    @surcharges_with_expiration_on_products = SurchargeWithExpiration.where(owner_type: "SurchargeOnProduct", owner_id: @all_surcharges_on_products.map(&:id))

    @first_day_this_month = Time.zone.now.beginning_of_month
    @first_day_next_month = @first_day_this_month.next_month
  end

  def all_surcharges
    @all_surcharges.map { |surcharge_on_carrier| SurchargeFields.new(view_model: self, surcharge_on_carrier: surcharge_on_carrier) }
  end

  def all_surcharges_on_products
    @all_surcharges_on_products
  end

  def enabled_surcharges
    @enabled_surcharges
  end

  def sorted_carrier_products
    @carrier_products.sort_by { |carrier_product| carrier_product.name.downcase }
  end

  def carrier_product_surcharge_rows
    sorted_carrier_products.map do |carrier_product|
      CarrierProductSurchargeRow.new(view_model: self, carrier_product: carrier_product)
    end
  end

  def get_surcharge_for_this_month(owner:)
    monthly_surcharge =
      @surcharges_with_expiration.detect do |s|
        s.owner_id == owner.id && s.same_month?(@first_day_this_month)
      end

    monthly_surcharge || SurchargeWithExpiration.new(owner: owner, valid_from: @first_day_this_month, expires_on: @first_day_this_month.end_of_month, surcharge: owner.surcharge.dup)
  end

  def get_product_level_surcharge_for_this_month(owner:)
    monthly_surcharge =
      @surcharges_with_expiration_on_products.detect do |s|
        s.owner_id == owner.id && s.same_month?(@first_day_this_month)
      end

    monthly_surcharge || SurchargeWithExpiration.new(owner: owner, valid_from: @first_day_this_month, expires_on: @first_day_this_month.end_of_month, surcharge: Surcharge.new)
  end

  def get_surcharge_for_next_month(owner:)
    monthly_surcharge =
      @surcharges_with_expiration.detect do |s|
        s.owner_id == owner.id && s.same_month?(@first_day_next_month)
      end

    monthly_surcharge || SurchargeWithExpiration.new(owner: owner, valid_from: @first_day_next_month, expires_on: @first_day_next_month.end_of_month, surcharge: Surcharge.new)
  end

  class CarrierProductSurchargeRow
    attr_reader :carrier_product

    def initialize(view_model:, carrier_product:)
      @view_model = view_model
      @carrier_product = carrier_product
    end

    def surcharge_columns
      @view_model.enabled_surcharges.map do |surcharge_on_carrier|
        CarrierProductSurchargeColumn.new(
          view_model: @view_model,
          carrier_product: carrier_product,
          surcharge_on_carrier: surcharge_on_carrier,
        )
      end
    end
  end

  class CarrierProductSurchargeColumn
    attr_reader :carrier_product
    attr_reader :surcharge_on_carrier
    attr_reader :surcharge_on_product

    def initialize(view_model:, carrier_product:, surcharge_on_carrier:)
      @view_model = view_model
      @carrier_product = carrier_product
      @surcharge_on_carrier = surcharge_on_carrier

      @surcharge_on_product = @view_model.all_surcharges_on_products.detect do |surcharge_on_product|
        surcharge_on_product.parent == @surcharge_on_carrier && surcharge_on_product.carrier_product == @carrier_product
      end
    end

    def product_level_override?
      !!@surcharge_on_product
    end

    def surcharge
      monthly_surcharge =
        if product_level_override?
          @view_model.get_product_level_surcharge_for_this_month(owner: @surcharge_on_product)
        else
          @view_model.get_surcharge_for_this_month(owner: @surcharge_on_carrier)
        end

      if monthly_surcharge.persisted?
        monthly_surcharge.surcharge
      elsif product_level_override?
        @surcharge_on_product.surcharge
      else
        @surcharge_on_carrier.surcharge
      end
    end
  end

  class SurchargeFields
    delegate(
      :id,
      :predefined_type,
      :enabled,
      :description,
      :charge_value,
      to: :@surcharge_on_carrier
    )

    delegate(
      :default_surcharge?,
      :carrier_feedback_surcharge?,
      :calculation_method,
      to: :surcharge
    )

    def initialize(view_model:, surcharge_on_carrier:)
      @view_model = view_model
      @surcharge_on_carrier = surcharge_on_carrier
    end

    def surcharge
      @surcharge_on_carrier.surcharge
    end

    def include_hidden_fields
      if @surcharge_on_carrier.new_record?
        [:predefined_type, :description]
      else
        [:id]
      end
    end

    def monthly_values?
      case @surcharge_on_carrier.surcharge.type
      when "FuelSurcharge"
        true
      else
        false
      end
    end

    def calculated_method_locked?
      @surcharge_on_carrier.surcharge.calculated_method_locked_to.present?
    end

    def surcharges_for_this_and_next_month
      [
        @view_model.get_surcharge_for_this_month(owner: @surcharge_on_carrier),
        @view_model.get_surcharge_for_next_month(owner: @surcharge_on_carrier),
      ]
    end
  end
end

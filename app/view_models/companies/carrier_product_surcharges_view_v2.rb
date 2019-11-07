class Companies::CarrierProductSurchargesViewV2
  attr_reader :current_company
  attr_reader :carrier

  def initialize(current_company:, carrier_product:)
    @current_company = current_company
    @carrier_product = carrier_product

    @all_surcharges = @carrier_product.list_all_surcharges
    @all_surcharges_on_products = SurchargeOnProduct.where(carrier_product: @carrier_product)

    @surcharges_with_expiration = SurchargeWithExpiration.where(owner_type: "SurchargeOnProduct", owner_id: @all_surcharges_on_products.map(&:id))

    @parent_surcharges_with_expiration = SurchargeWithExpiration.where(owner_type: "SurchargeOnCarrier", owner_id: SurchargeOnCarrier.where(carrier: @carrier_product.carrier).pluck(:id))

    @first_day_this_month = Time.zone.now.beginning_of_month
    @first_day_next_month = @first_day_this_month.next_month
  end

  def all_surcharges
    @all_surcharges.map { |surcharge_on_product| SurchargeFields.new(view_model: self, surcharge_on_product: surcharge_on_product) }
  end

  def all_surcharges_on_products
    @all_surcharges_on_products
  end

  def get_surcharge_for_this_month(owner:)
    get_surcharge_with_expiration(owner: owner, first_day_in_month: @first_day_this_month)
  end

  def get_surcharge_for_next_month(owner:)
    get_surcharge_with_expiration(owner: owner, first_day_in_month: @first_day_next_month)
  end

  def get_surcharge_with_expiration(owner:, first_day_in_month:)
    monthly_surcharge =
      @surcharges_with_expiration.detect do |s|
        s.owner_id == owner.id && s.same_month?(first_day_in_month)
      end

    return monthly_surcharge if monthly_surcharge

    parent_monthly_surcharge =
      @parent_surcharges_with_expiration.detect do |s|
        s.owner_id == owner.parent_id && s.same_month?(first_day_in_month)
      end

    SurchargeWithExpiration.new(
      owner: owner,
      valid_from: first_day_in_month,
      expires_on: first_day_in_month.end_of_month,
      surcharge: parent_monthly_surcharge ? parent_monthly_surcharge.surcharge.dup : Surcharge.new,
    )
  end

  class SurchargeFields
    delegate(
      :id,
      :parent_id,
      :enabled,
      :description,
      :charge_value,
      to: :@surcharge_on_product
    )

    delegate(
      :default_surcharge?,
      :carrier_feedback_surcharge?,
      :calculation_method,
      to: :surcharge
    )

    def initialize(view_model:, surcharge_on_product:)
      @view_model = view_model
      @surcharge_on_product = surcharge_on_product
    end

    def surcharge
      @surcharge_on_product.surcharge
    end

    def include_hidden_fields
      if @surcharge_on_product.new_record?
        [:parent_id]
      else
        [:id]
      end
    end

    def monthly_values?
      case @surcharge_on_product.surcharge.type
      when "FuelSurcharge"
        true
      else
        false
      end
    end

    def calculated_method_locked?
      @surcharge_on_product.surcharge.calculated_method_locked_to.present?
    end

    def surcharges_for_this_and_next_month
      [
        @view_model.get_surcharge_for_this_month(owner: @surcharge_on_product),
        @view_model.get_surcharge_for_next_month(owner: @surcharge_on_product),
      ]
    end
  end
end

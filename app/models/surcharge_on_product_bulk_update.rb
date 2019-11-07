class SurchargeOnProductBulkUpdate
  attr_reader :carrier_product
  attr_reader :surcharges_attributes
  attr_reader :current_user

  def initialize(carrier_product:, surcharges_attributes:, current_user: nil)
    @carrier_product = carrier_product
    @surcharges_attributes = surcharges_attributes.is_a?(Hash) ? surcharges_attributes.values : surcharges_attributes
    @current_user = current_user
  end

  def perform!
    return true if surcharges_attributes.blank?

    ActiveRecord::Base.transaction do
      surcharges_attributes.each do |surcharge_attrs|
        surcharge_upsert =
          SurchargeUpsert.new(
            carrier_product: carrier_product,
            attrs: surcharge_attrs,
            id: surcharge_attrs[:id],
            parent_id: surcharge_attrs[:parent_id],
            current_user: current_user,
          )

        surcharge_upsert.perform!
      end
    end

    true
  end

  class SurchargeUpsert
    def initialize(carrier_product:, attrs:, id: nil, parent_id: nil, current_user: nil)
      @carrier_product = carrier_product
      @surcharge_on_product = SurchargeOnProduct.where(carrier_product: carrier_product).for_bulk_update(id: id, parent_id: parent_id)
      @attrs = attrs
      @current_user = current_user
    end

    def perform!
      # Assign
      surcharge_on_product.assign_attributes(permitted_attrs)
      surcharge_on_product.created_by = current_user
      surcharge_on_product.carrier_product = carrier_product

      # Persist
      surcharge_on_product.surcharge.save!
      surcharge_on_product.save!
      persist_monthly_surcharge_values!

      true
    end

    private

    def permitted_attrs
      attrs.slice(:enabled, :description, :charge_value, :calculation_method)
    end

    def persist_monthly_surcharge_values!
      return true if attrs[:monthly].blank?

      attrs[:monthly].each do |_, monthly_surcharge_attrs|
        datetime_attrs = monthly_surcharge_attrs.slice(:valid_from, :expires_on).to_unsafe_hash
        datetime_attrs.each do |key, value|
          datetime_attrs[key] = Time.zone.parse(value)
        end

        monthly_surcharge = SurchargeWithExpiration.where(owner: surcharge_on_product).find_or_initialize_by(datetime_attrs)
        monthly_surcharge.build_surcharge unless monthly_surcharge.surcharge
        monthly_surcharge.charge_value = monthly_surcharge_attrs[:charge_value]

        if monthly_surcharge.charge_value.blank?
          monthly_surcharge.destroy if monthly_surcharge.persisted?
          next
        end

        # Inherit values from "owner".
        monthly_surcharge.surcharge.type = surcharge_on_product.surcharge.type
        monthly_surcharge.surcharge.description = surcharge_on_product.surcharge.description
        monthly_surcharge.surcharge.calculation_method = surcharge_on_product.surcharge.calculation_method

        monthly_surcharge.save!
        monthly_surcharge.surcharge.save!
      end
    end

    attr_reader :carrier_product
    attr_reader :surcharge_on_product
    attr_reader :attrs
    attr_reader :current_user
  end
end

class SurchargeOnCarrierBulkUpdate
  attr_reader :carrier
  attr_reader :surcharges_attributes
  attr_reader :current_user

  def initialize(carrier:, surcharges_attributes:, current_user: nil)
    @carrier = carrier
    @surcharges_attributes = surcharges_attributes.is_a?(Hash) ? surcharges_attributes.values : surcharges_attributes
    @current_user = current_user
  end

  def perform!
    return true if surcharges_attributes.blank?

    ActiveRecord::Base.transaction do
      surcharges_attributes.each do |surcharge_attrs|
        surcharge_upsert =
          SurchargeUpsert.new(
            carrier: carrier,
            attrs: surcharge_attrs,
            id: surcharge_attrs[:id],
            predefined_type: surcharge_attrs[:predefined_type],
            current_user: current_user,
          )

        surcharge_upsert.perform!
      end
    end

    true
  end

  class SurchargeUpsert
    def initialize(carrier:, attrs:, id: nil, predefined_type: nil, current_user: nil)
      @carrier = carrier
      @surcharge_on_carrier = SurchargeOnCarrier.for_bulk_update(carrier, id: id, predefined_type: predefined_type)
      @attrs = attrs
      @current_user = current_user
    end

    def perform!
      # Assign
      surcharge_on_carrier.assign_attributes(permitted_attrs)
      surcharge_on_carrier.created_by = current_user
      surcharge_on_carrier.carrier = carrier

      # Persist
      surcharge_on_carrier.surcharge.save!
      surcharge_on_carrier.save!
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

        monthly_surcharge = SurchargeWithExpiration.where(owner: surcharge_on_carrier).find_or_initialize_by(datetime_attrs)
        monthly_surcharge.build_surcharge unless monthly_surcharge.surcharge
        monthly_surcharge.charge_value = monthly_surcharge_attrs[:charge_value]

        if monthly_surcharge.charge_value.blank?
          monthly_surcharge.destroy if monthly_surcharge.persisted?
          next
        end

        # Inherit values from "owner".
        monthly_surcharge.surcharge.type = surcharge_on_carrier.surcharge.type
        monthly_surcharge.surcharge.description = surcharge_on_carrier.surcharge.description
        monthly_surcharge.surcharge.calculation_method = surcharge_on_carrier.surcharge.calculation_method

        monthly_surcharge.save!
        monthly_surcharge.surcharge.save!
      end
    end

    attr_reader :carrier
    attr_reader :surcharge_on_carrier
    attr_reader :attrs
    attr_reader :current_user
  end
end

module BelongsToSurcharge
  extend ActiveSupport::Concern

  included do
    belongs_to :surcharge, required: false, dependent: :destroy

    delegate(
      :description, :description=,
      :charge_value, :charge_value=,
      :calculation_method, :calculation_method=,
      :formatted_value,
      to: :surcharge,
    )

    attr_accessor :created_by
  end

  def enabled=(value)
    if ["1", true].include?(value)
      self.disabled_at = nil
    else
      self.disabled_at = Time.zone.now if enabled?
    end
  end

  def enabled?
    !disabled_at?
  end

  def enabled
    enabled?
  end

  def active_surcharge(now: Time.zone.now)
    # FIXME: This is sort of hacky but for now we only need fuel surcharges to be expirable.
    case surcharge
    when FuelSurcharge
      surcharge_with_expiration = SurchargeWithExpiration.where(owner: self).nearest_valid_from(now)
      return surcharge_with_expiration.surcharge if surcharge_with_expiration
    end

    surcharge
  end
end

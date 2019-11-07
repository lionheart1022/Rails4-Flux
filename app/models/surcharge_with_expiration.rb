class SurchargeWithExpiration < ActiveRecord::Base
  self.table_name = "surcharges_with_expiration"

  belongs_to :owner, required: true, polymorphic: true
  belongs_to :surcharge, required: true, dependent: :destroy

  delegate(
    :description, :description=,
    :charge_value, :charge_value=,
    :calculation_method, :calculation_method=,
    :formatted_value,
    to: :surcharge,
  )

  class << self
    def applicable_for_datetime(datetime)
      self
        .where(arel_table[:valid_from].lteq(datetime))
        .where(arel_table[:expires_on].gteq(datetime))
    end

    def valid_from(datetime)
      self.where(arel_table[:valid_from].lteq(datetime))
    end

    def nearest_valid_from(from)
      valid_from(from).order(:valid_from => :desc).first
    end
  end

  def formatted_month(format: "%b'%y")
    valid_from.strftime(format) if valid_from?
  end

  def same_month?(datetime)
    return false if valid_from.nil? || expires_on.nil?

    f = "%Y-%m"

    valid_from.strftime(f) == datetime.strftime(f) && expires_on.strftime(f) == datetime.end_of_month.strftime(f)
  end
end

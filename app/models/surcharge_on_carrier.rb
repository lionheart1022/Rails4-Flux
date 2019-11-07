class SurchargeOnCarrier < ActiveRecord::Base
  include BelongsToSurcharge

  self.table_name = "surcharges_on_carriers"

  belongs_to :carrier, required: true
  has_many :surcharges_with_expiration, class_name: "SurchargeWithExpiration", as: :owner, dependent: :destroy

  attr_accessor :predefined_type

  class << self
    def for_bulk_update(carrier, id: nil, predefined_type: nil)
      if id.present?
        where(carrier: carrier).find(id)
      elsif predefined_type == "fuel"
        carrier.find_fuel_charge
      elsif predefined_type == "residential"
        carrier.find_residential_surcharge
      elsif predefined_type.present?
        new(carrier: carrier, surcharge: Surcharge.build_surcharge_by_predefined_type(predefined_type), enabled: false)
      else
        raise "id or predefined_type should be set"
      end
    end
  end
end

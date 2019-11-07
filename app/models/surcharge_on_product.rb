class SurchargeOnProduct < ActiveRecord::Base
  include BelongsToSurcharge

  self.table_name = "surcharges_on_products"

  belongs_to :parent, required: true, class_name: "SurchargeOnCarrier"
  belongs_to :carrier_product, required: true
  has_many :surcharges_with_expiration, class_name: "SurchargeWithExpiration", as: :owner, dependent: :destroy

  before_validation :whitelist_parent

  class << self
    def for_bulk_update(id: nil, parent_id: nil)
      if id.present?
        find(id)
      else
        parent = SurchargeOnCarrier.find(parent_id)
        new(surcharge: parent.surcharge.dup, parent: parent, enabled: false)
      end
    end
  end

  def like_parent?
    return false if parent.nil?

    self.enabled? == parent.enabled? && self.surcharge.similar?(parent.surcharge)
  end

  private

  def whitelist_parent
    if carrier_product
      self.parent = SurchargeOnCarrier.find_by(carrier_id: carrier_product.carrier_id, id: parent_id)
    end

    true
  end
end

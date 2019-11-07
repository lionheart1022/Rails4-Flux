class EconomicProductMapping < ActiveRecord::Base
  belongs_to :owner, polymorphic: true, required: true
  belongs_to :item, polymorphic: true, required: true

  before_save :set_product_name_incl_vat_from_product
  before_save :set_product_name_excl_vat_from_product

  def active_access
    EconomicAccess.active.find_by(owner: owner)
  end

  def available_economic_products
    EconomicProduct.where(access: active_access).order(:number, :name)
  end

  # Used for generating a (most likely) unique HTML ID attribute
  # The memoization is essential as it will be outputted multiple times in the view partial
  def product_number_incl_vat_digest; @_product_number_incl_vat_digest ||= "product_number_incl_vat__#{SecureRandom.hex(4)}"; end
  def product_number_excl_vat_digest; @_product_number_excl_vat_digest ||= "product_number_excl_vat__#{SecureRandom.hex(4)}"; end

  private

  def set_product_name_incl_vat_from_product
    self.product_name_incl_vat =
      if product_number_incl_vat?
        EconomicProduct.where(access: active_access, number: product_number_incl_vat).pluck(:name).first
      else
        nil
      end
  end

  def set_product_name_excl_vat_from_product
    self.product_name_excl_vat =
      if product_number_excl_vat?
        EconomicProduct.where(access: active_access, number: product_number_excl_vat).pluck(:name).first
      else
        nil
      end
  end
end

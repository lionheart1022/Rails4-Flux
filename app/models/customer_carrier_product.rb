class CustomerCarrierProduct < ActiveRecord::Base
  belongs_to :customer
  belongs_to :carrier_product
  has_one    :sales_price, as: :reference

  validates_presence_of :customer

  accepts_nested_attributes_for :sales_price

  class << self

    def build_customer_carrier_product(customer_id: nil, carrier_product_id: nil)
        customer_carrier_product = self.new({
           customer_id:             customer_id,
           carrier_product_id:      carrier_product_id,
           is_disabled:             true,
           enable_autobooking:      false,
           automatically_autobook:  false,
        })

        return customer_carrier_product
    end

    def create_customer_carrier_product(customer_id: nil, carrier_product_id: nil)
      transaction do

        customer_carrier_product = self.build_customer_carrier_product(customer_id: customer_id, carrier_product_id: carrier_product_id)
        customer_carrier_product.save!

        SalesPrice.create_sales_price(reference_id: customer_carrier_product.id, reference_type: self.to_s)

        return customer_carrier_product
      end
    end

    # Finders

    # @return [Array<CustomerCarrierProduct>]
    def find_customer_carrier_products_not_in_ids(customer_id: nil, carrier_product_ids: nil)
      self.where(customer_id: customer_id).where("carrier_product_id not in (?)", carrier_product_ids)
    end

    # @return [CustomerCarrierProduct]
    def find_customer_carrier_product(customer_id: nil, carrier_product_id: nil)
      self.where(customer_id: customer_id, carrier_product_id: carrier_product_id).first
    end

    # @return [Array<CustomerCarrierProduct>]
    def find_or_create_customer_carrier_products_for_carrier_products(customer_id: nil, carrier_products: nil)
      customer_carrier_products = []

      carrier_products.each do |carrier_product|
        customer_carrier_product = self.find_customer_carrier_product(customer_id: customer_id, carrier_product_id: carrier_product.id)
        customer_carrier_product = self.create_customer_carrier_product(customer_id: customer_id, carrier_product_id: carrier_product.id) unless customer_carrier_product

        customer_carrier_products << customer_carrier_product
      end

      return customer_carrier_products
    end

    def find_enabled_customer_carrier_products(customer_id: nil)
      CarrierProduct.select("carrier_products.*, customer_carrier_products.is_disabled as customer_carrier_product_is_disabled")
        .joins("left join customer_carrier_products on customer_carrier_products.carrier_product_id=carrier_products.id")
        .where("customer_carrier_products.customer_id = ?", customer_id)
        .where("case when customer_carrier_products.is_disabled = true or carrier_products.is_disabled = true then true else false end = ?", false)
        .where("customer_carrier_products.customer_id = ?", customer_id)
    end
  end

  def is_enabled
    !is_disabled
  end

  alias_method :is_enabled?, :is_enabled

  def is_enabled=(value)
    self.is_disabled = !(["1", "true"].include?(value.to_s))
  end

  def margin_percentage
    if sales_price
      sales_price.margin_percentage
    end
  end

  def margin_percentage=(value)
    build_sales_price if sales_price.nil?
    sales_price.margin_percentage = value
  end

  def margin_type
    return if sales_price.nil?

    if sales_price.use_margin_config?
      "intervals"
    else
      "percentage"
    end
  end

  def margin_type=(value)
    build_sales_price if sales_price.nil?
    sales_price.use_margin_config = (value == "intervals")
  end
end

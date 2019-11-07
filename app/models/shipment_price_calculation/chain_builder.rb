class ShipmentPriceCalculation::ChainBuilder
  attr_accessor :carrier_product
  attr_accessor :company_id
  attr_accessor :customer_id

  def initialize(attrs = {})
    attrs.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def as_array
    links_for_carrier_product_customers + [link_for_customer]
  end

  private

  def link_for_customer
    ChainLink.new(
      seller: carrier_product.company,
      buyer: Customer.where(company_id: company_id).find(customer_id),
      sales_price: CustomerCarrierProduct.find_by!(customer_id: customer_id, carrier_product: carrier_product).sales_price,
    )
  end

  def links_for_carrier_product_customers
    carrier_products = ordered_carrier_product_chain

    return [] if carrier_products.length.zero?

    carrier_products[0..-2].zip(carrier_products[1..-1]).map do |(carrier_product, next_carrier_product)|
      ChainLink.new(
        seller: carrier_product.company,
        buyer: next_carrier_product.company,
        sales_price: next_carrier_product.sales_price,
      )
    end
  end

  def ordered_carrier_product_chain
    carrier_products = carrier_product.owner_carrier_product_chain(include_self: true).reverse

    if carrier_products.length > 1 && !carrier_products.first.custom?
      # The top-level carrier product is (usually) the product belonging to the CF company.
      # We want to exclude the top-level because we should not calculate a price for the CF company.
      # This decision also means that if a non-custom product belongs to a regular company at the top-level then the price calculations
      # will only be as expected for their own customers but not for carrier product customers.
      #
      # This is something we should look into and fix. A solution could be to only exclude the top-level carrier product _if_
      # the company is actually CF - this we can find out with the `can_manage_companies` Permission.
      carrier_products[1..-1]
    else
      carrier_products
    end
  end

  # A physical chain consists of _links_ of metal rings - thus the name `link`.
  class ChainLink
    attr_accessor :seller
    attr_accessor :buyer
    attr_accessor :sales_price

    def initialize(attrs = {})
      attrs.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end
  end
end

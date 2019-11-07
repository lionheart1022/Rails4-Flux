class Companies::CarrierProductCustomers::Carriers::Products::ListView
  attr_reader :main_view, :customer, :carrier, :carrier_products

  def initialize(customer: nil, carrier: nil, carrier_products: nil)
    @customer         = customer
    @carrier          = carrier
    @carrier_products = carrier_products
    state_general
  end

  def header_text
    "#{@customer.name} - #{carrier.name} Carrier"
  end

  def show_product_table?
    @carrier_products.count > 0
  end

  def any_checked?
    @carrier_products.any? { |cp| cp.is_disabled }
  end

  private

  def state_general
    @main_view = "components/companies/carrier_product_customers/carriers/products/index"
  end
end
